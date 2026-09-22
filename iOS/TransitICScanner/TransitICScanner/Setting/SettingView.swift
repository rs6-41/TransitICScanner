import SwiftUI

struct SettingView: View {
    @AppStorage("deleteAds") var deleteAds = false
    @Binding var deleteAdsPurchaseID:String
    
    @State var isPurchaseAlert = false
    @State var purchaseAlertTitle:String = ""
    @State var purchaseAlertMessage:String = ""
    
    @AppStorage("cloudSyncEnabled") var isCloudSyncEnabled = true
    
    let appEnvironment = Bundle.main.object(
        forInfoDictionaryKey: "AppEnvironment"
    ) as? String
    
    var body: some View {
        NavigationStack {
            List {
                SettingAppTitle()
                
                if !deleteAds {
                    SettingAdsPurchase(deleteAdsPurchaseID: $deleteAdsPurchaseID, purchaseAlertTitle: $purchaseAlertTitle, purchaseAlertMessage: $purchaseAlertMessage, isPurchaseAlert: $isPurchaseAlert, deleteAds: $deleteAds)
                }
                
                SettingData(isCloudSyncEnabled:$isCloudSyncEnabled)
                
                Section(header:Text(LocalizedStringKey("setting.feature"))) {
                    NavigationLink(destination: SettingFeatureView()) {
                        SquareIcon(text:"setting.feature", systemImage: "testtube.2",color:Color.purple)
                    }
                }
                
                Section(header:Text(LocalizedStringKey("setting.other"))) {
                    NavigationLink(destination: AcknowledgmentView()) {
                        SquareIcon(text:"setting.acknowledgment", systemImage: "info.bubble.fill",color:Color.gray)
                    }
                    if appEnvironment == "DEV" {
                        NavigationLink(destination: DebugSettingView(deleteAdsPurchaseID: $deleteAdsPurchaseID, deleteAds: $deleteAds)) {
                            SquareIcon(text:"setting.debug", systemImage: "hammer.fill",color:Color.blue)
                        }
                    }
                }
            }
            .listSectionSpacing(.compact)
            .contentMargins(.top, 0)
            .environment(\.defaultMinListRowHeight, 1)
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                .zero
            }
            .navigationTitle(LocalizedStringKey("tab.setting"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .alert(purchaseAlertTitle, isPresented: $isPurchaseAlert) {
               Button(LocalizedStringKey("ok")) {
                   purchaseAlertTitle = ""
                   purchaseAlertMessage = ""
                   isPurchaseAlert = false
               }
            } message: {
                Text(purchaseAlertMessage)
            }
        }
    }
}


#Preview {
    SettingView(deleteAdsPurchaseID: .constant("com.rs6apps.TransitICScanner.deleteAds.test"))
}
