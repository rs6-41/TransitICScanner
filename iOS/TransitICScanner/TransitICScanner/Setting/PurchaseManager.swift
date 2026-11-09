import Foundation
import StoreKit

/// 広告削除（非消耗型）の購入状態を管理する
///
/// - 購入・復元・他の端末での購入・返金を StoreKit の Transaction から判定し、`deleteAds` に反映する
/// - 検証できない取引は購入済みとして扱わない
/// - 処理した取引は必ず `finish()` する
@MainActor
final class PurchaseManager {
    static let shared = PurchaseManager()

    /// `@AppStorage("deleteAds")` と同じキー
    private static let deleteAdsKey = "deleteAds"
    /// `@AppStorage("deleteAdsPurchaseID")` と同じキー
    private static let productIDKey = "deleteAdsPurchaseID"

    private var updatesTask: Task<Void, Never>?

    private init() {}

    private var productID: String {
        UserDefaults.standard.string(forKey: Self.productIDKey)
            ?? "com.rs6apps.TransitICScanner.deleteAds"
    }

    /// 取引の更新（他の端末での購入、承認待ちの完了、返金など）の監視を開始する
    func startObservingTransactions() {
        guard updatesTask == nil else { return }

        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
    }

    /// 現在の購入状態を StoreKit から取得して `deleteAds` に反映する
    func refreshEntitlement() async {
        let entitled = await hasEntitlement()

        if entitled {
            setDeleteAds(true)
        } else if AppEnvironment.current == .rel {
            // 返金などで権利がなくなった場合は広告表示に戻す
            // （DEV / BETA はデバッグ設定で切り替えるため自動では戻さない）
            setDeleteAds(false)
        }
    }

    /// 購入結果を処理する。検証できない取引の場合はエラーを投げる。
    func handlePurchase(_ result: Product.PurchaseResult) async throws -> PurchaseOutcome {
        switch result {
        case .success(let verification):
            let transaction = try verified(verification)
            await transaction.finish()
            setDeleteAds(transaction.revocationDate == nil)
            return .purchased
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    /// App Store と同期して購入を復元する。復元できた場合は true を返す。
    func restore() async throws -> Bool {
        try await AppStore.sync()
        let entitled = await hasEntitlement()
        if entitled {
            setDeleteAds(true)
        }
        return entitled
    }

    enum PurchaseOutcome {
        case purchased
        case pending
        case cancelled
    }

    // MARK: - Private

    private func handle(_ update: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = update else {
            Log.error("検証できない取引を受信したため無視しました")
            return
        }

        if transaction.productID == productID {
            setDeleteAds(transaction.revocationDate == nil)
        }

        await transaction.finish()
    }

    private func hasEntitlement() async -> Bool {
        for await entitlement in Transaction.currentEntitlements(for: productID) {
            if case .verified(let transaction) = entitlement,
                transaction.revocationDate == nil
            {
                return true
            }
        }
        return false
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified(_, let error):
            throw error
        }
    }

    private func setDeleteAds(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Self.deleteAdsKey)
    }
}
