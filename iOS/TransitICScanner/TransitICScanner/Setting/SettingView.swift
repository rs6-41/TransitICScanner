import SwiftUI
import Combine
import SwiftData

struct SettingView: View {
    @Binding var deleteAds:Bool
    @Binding var deleteAdsPurchaseID:String
    
    @State var isPurchaseAlert = false
    @State var purchaseAlertTitle:String = ""
    @State var purchaseAlertMessage:String = ""
    
    @Binding var isCloudSyncEnabled:Bool
    
    let appEnvironment = Bundle.main.object(
        forInfoDictionaryKey: "AppEnvironment"
    ) as? String
    @AppStorage("devSetting") var devSetting = false
    @State var devSettingAlert = false
    
    
    var body: some View {
        NavigationStack {
            List {
                SettingAppTitle(devSettingAlert:$devSettingAlert)
                
                if adDeleteDisplay {
                    if !deleteAds {
                        SettingAdsPurchase(deleteAdsPurchaseID: $deleteAdsPurchaseID, purchaseAlertTitle: $purchaseAlertTitle, purchaseAlertMessage: $purchaseAlertMessage, isPurchaseAlert: $isPurchaseAlert, deleteAds: $deleteAds)
                    }
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
                    if appEnvironment == "DEV" || devSetting {
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
            
            
            .alert("setting.debug.enable.title", isPresented: $devSettingAlert) {
                Button(LocalizedStringKey("cancel"), role: .cancel) {
                    devSetting = false
                }
                Button(LocalizedStringKey("setting.debug.enable.ok"),role:.destructive) {
                   devSetting = true
               }
            } message: {
                Text("setting.debug.enable.description")
            }
        }
    }
}


#Preview {
    SettingView(deleteAds: .constant(false), deleteAdsPurchaseID: .constant("com.rs6apps.TransitICScanner.deleteAds.test"), isCloudSyncEnabled: .constant(false))
}
