import SwiftUI
import StoreKit

struct SettingAdsPurchase: View {
    @Binding var deleteAdsPurchaseID:String
    @Binding var purchaseAlertTitle:String
    @Binding var purchaseAlertMessage:String
    @Binding var isPurchaseAlert:Bool
    @Binding var deleteAds:Bool
    var body: some View {
        Section(header:Text("setting.ads")) {
            HStack {
                SquareIcon(text:"", systemImage: "xmark.app.fill",color:Color.green)
                ProductView(id: deleteAdsPurchaseID)
                    .productViewStyle(.compact)
                    .onInAppPurchaseCompletion { product, result in
                        switch result {
                            case .success(let purchaseResult):
                                switch purchaseResult {
                                    case .success(_):
                                        purchaseAlertTitle = String(localized:"setting.ads.purchase.done")
                                        purchaseAlertMessage = String(localized:"setting.ads.purchase.done.message")
                                        isPurchaseAlert = true
                                        deleteAds = true
                                    case .userCancelled: break //キャンセル
                                    @unknown default: break
                                }
                            case .failure(let error):
                                purchaseAlertTitle = String(localized:"setting.ads.purchase.error")
                                purchaseAlertMessage = error.localizedDescription
                                isPurchaseAlert = true
                    }
                }
            }
            Button(action: {
                Task {
                    do {
                        try await AppStore.sync()
                        
                        for await verificationResult in Transaction.currentEntitlements(for:deleteAdsPurchaseID) {
                                switch verificationResult {
                                case .verified(_):
                                    purchaseAlertTitle = String(localized:"setting.ads.restore.done")
                                    purchaseAlertMessage = String(localized:"setting.ads.restore.done.message")
                                    isPurchaseAlert = true
                                    deleteAds = true
                                case .unverified(_, let verificationError):
                                    purchaseAlertTitle = String(localized:"setting.ads.restore.unverified")
                                    purchaseAlertMessage = verificationError.localizedDescription
                                    isPurchaseAlert = true
                                }
                            }
                    } catch {
                        purchaseAlertTitle = String(localized:"setting.ads.restore.unverified")
                        purchaseAlertMessage = error.localizedDescription
                        isPurchaseAlert = true
                    }
                }
            }) {
                SquareIcon(text:"setting.ads.restore", systemImage: "arrow.counterclockwise.circle",color:Color.orange)
            }
        }
    }
}
