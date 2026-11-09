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
                ProductView(id: deleteAdsPurchaseID) {
                    SquareIcon(systemImage: "xmark.app.fill",color:Color.green)
                }
                    .buttonStyle(ProductButtonStyle())
                    .productViewStyle(.compact)
                
                    .onInAppPurchaseCompletion { product, result in
                        switch result {
                        case .success(let purchaseResult):
                            do {
                                switch try await PurchaseManager.shared.handlePurchase(purchaseResult) {
                                case .purchased:
                                    purchaseAlertTitle = String(localized:"setting.ads.purchase.done")
                                    purchaseAlertMessage = String(localized:"setting.ads.purchase.done.message")
                                    isPurchaseAlert = true
                                    deleteAds = true
                                case .pending:
                                    // 承認待ち（ファミリー共有の承認など）。完了時は Transaction.updates で反映される
                                    purchaseAlertTitle = String(localized:"setting.ads.purchase.pending")
                                    purchaseAlertMessage = String(localized:"setting.ads.purchase.pending.message")
                                    isPurchaseAlert = true
                                case .cancelled:
                                    break
                                }
                            } catch {
                                purchaseAlertTitle = String(localized:"setting.ads.restore.unverified")
                                purchaseAlertMessage = error.localizedDescription
                                isPurchaseAlert = true
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
                        if try await PurchaseManager.shared.restore() {
                            purchaseAlertTitle = String(localized:"setting.ads.restore.done")
                            purchaseAlertMessage = String(localized:"setting.ads.restore.done.message")
                            deleteAds = true
                        } else {
                            purchaseAlertTitle = String(localized:"setting.ads.restore.notFound")
                            purchaseAlertMessage = String(localized:"setting.ads.restore.notFound.message")
                        }
                        isPurchaseAlert = true
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

struct ProductButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .padding(.vertical,6)
            .padding(.horizontal,20)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(50)
            .glassEffect()
    }
}
