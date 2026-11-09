import SwiftUI
import Combine
#if !targetEnvironment(macCatalyst)
import GoogleMobileAds
import UserMessagingPlatform
#endif

/// 広告の同意取得（Google User Messaging Platform）
///
/// EEA・英国などでは、広告を配信する前に同意を取得する必要がある。
/// - 起動時（初回の権限説明が終わった後）に `gatherConsent()` を呼び、必要なら同意フォームを表示する
/// - `canRequestAds` が true になってから Mobile Ads SDK を初期化し、広告を読み込む
/// - 同意の変更が必要な地域では、設定画面から `presentPrivacyOptions()` を呼べるようにする
@MainActor
final class AdConsentManager: ObservableObject {
    static let shared = AdConsentManager()

    /// 広告をリクエストしてよいか
    @Published private(set) var canRequestAds = false
    /// 設定画面にプライバシーオプション（同意の変更）を表示する必要があるか
    @Published private(set) var isPrivacyOptionsRequired = false

    private var isMobileAdsStarted = false
    private var isGathering = false

    private init() {
        // 前回の起動で同意済みなら、同意情報の更新を待たずに広告を始められる
        refreshStatus()
    }

    /// 同意情報を更新し、必要なら同意フォームを表示する
    func gatherConsent() async {
        #if !targetEnvironment(macCatalyst)
        guard !isGathering else { return }
        isGathering = true
        defer { isGathering = false }

        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            Log.error("広告の同意情報の取得に失敗: \(error.localizedDescription)")
        }

        refreshStatus()
        #endif
    }

    /// 同意の内容を変更するフォームを表示する
    func presentPrivacyOptions() async {
        #if !targetEnvironment(macCatalyst)
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
            Log.error("プライバシーオプションの表示に失敗: \(error.localizedDescription)")
        }

        refreshStatus()
        #endif
    }

    private func refreshStatus() {
        #if !targetEnvironment(macCatalyst)
        canRequestAds = ConsentInformation.shared.canRequestAds
        isPrivacyOptionsRequired =
            ConsentInformation.shared.privacyOptionsRequirementStatus == .required

        if canRequestAds && !isMobileAdsStarted {
            isMobileAdsStarted = true
            MobileAds.shared.start(completionHandler: nil)
        }
        #endif
    }
}
