import SwiftUI
import Combine
#if !targetEnvironment(macCatalyst)
import GoogleMobileAds
#endif
import AdSupport
import AppTrackingTransparency

// 現時点では購入オプションを非表示
var adDeleteDisplay = false

final class AdsModel: ObservableObject {
    @Published var isDeleteAdsSheet = false
    @Published var purchaseAlertTitle = ""
    @Published var purchaseAlertMessage = ""
    @Published var isPurchaseAlert = false
}

struct ContentView: View {
    @State var tab: Int = 0
    @AppStorage("deleteAdsPurchaseID") var deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds"
    @AppStorage("enableCardType") var enableCardType = 0
    @AppStorage("testCardEnabled") var isTestCardEnabled = false
    
    @AppStorage("isLaunchVersionFastBeta") var isLaunchVersionFastBeta = ""
    @AppStorage("isLaunchVersionFastRel") var isLaunchVersionFastRel = ""
    let appEnvironment = Bundle.main.object(
        forInfoDictionaryKey: "AppEnvironment"
    ) as? String
    
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    @State var versionFirstLook = false
    @AppStorage("devSetting") var devSetting = false
    @AppStorage("deleteAds") var deleteAds = false
    @AppStorage("adDebug") var adDebug = false
    @AppStorage("cloudSyncEnabled") var isCloudSyncEnabled = true
    
    @EnvironmentObject var debug: DebugModel
    @EnvironmentObject var ads: AdsModel
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var smartCardManager = SmartCardManager()
    
    
    @AppStorage("isDebugStorage") var isDebugStorage = false
    
    @AppStorage("firstPermission") var firstPermission = true
    
    var body: some View {
        TabView(selection: $tab) {
            CardList(deleteAds: $deleteAds,smartCardManager: smartCardManager)
                .tag(0)
                .toolbarBackground(.visible, for: .tabBar)
                .tabItem {
                    Label(String(localized:"tab.scan"), systemImage: "iphone.radiowaves.left.and.right")
                }
            SavedListView(deleteAds: $deleteAds)
                .tag(1)
                .toolbarBackground(.visible, for: .tabBar)
                .tabItem {
                    Label(String(localized:"tab.history"), systemImage: "tram.card")
                }
            if appEnvironment == "DEV" {
                NFCToolView(deleteAds: $deleteAds)
                    .tag(2)
                    .toolbarBackground(.visible, for: .tabBar)
                    .tabItem {
                        Label(String(localized:"tab.tool"), systemImage: "latch.2.case.fill")
                    }
            }
            SettingView(deleteAds: $deleteAds, deleteAdsPurchaseID: $deleteAdsPurchaseID, isCloudSyncEnabled: $isCloudSyncEnabled)
                .tag(3)
                .toolbarBackground(.visible, for: .tabBar)
                .tabItem {
                    Label(String(localized:"tab.setting"), systemImage: "gearshape")
                }
        }
        
        .task {
            smartCardManager.start()
        }
        .sheet(isPresented: $firstPermission) {
            PermissionModalView(isPresented: $firstPermission)
                .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $ads.isDeleteAdsSheet) {
            NavigationStack {
                List {
                    SettingAdsPurchase(deleteAdsPurchaseID: $deleteAdsPurchaseID, purchaseAlertTitle: $ads.purchaseAlertTitle, purchaseAlertMessage: $ads.purchaseAlertMessage, isPurchaseAlert: $ads.isPurchaseAlert, deleteAds: $deleteAds)
                        .alert(ads.purchaseAlertTitle, isPresented: $ads.isPurchaseAlert) {
                            Button(LocalizedStringKey("ok")) {
                                ads.purchaseAlertTitle = ""
                                ads.purchaseAlertMessage = ""
                                ads.isPurchaseAlert = false
                                ads.isDeleteAdsSheet = false
                            }
                        } message: {
                            Text(ads.purchaseAlertMessage)
                        }
                }
                .navigationTitle(LocalizedStringKey("ads.delete"))
                .toolbar {
                    ToolbarItem(placement:.cancellationAction){
                        Button(action: {
                            dismiss()
                            ads.isDeleteAdsSheet = false
                        }) {
                            Image(systemName:"xmark")
                        }
                    }
                }
            }
        }
        
        .onAppear() {
            setup()
        }
    }
    private func setup() {
        devSetting = false
        
        switch appEnvironment {
        case "DEV":
            deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds.test"
            cardItemsStore.cardItems = devCards + featureCards + relCards
            adDebug = true
            debugStorage(isDebugStorage)
            
        case "BETA":
            deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds.test"
            if version != isLaunchVersionFastBeta {
                isTestCardEnabled = true
                isLaunchVersionFastBeta = version
                firstLook()
            }
            if isTestCardEnabled {
                cardItemsStore.cardItems = featureCards + relCards
            } else {
                cardItemsStore.cardItems = relCards
            }
            isDebugStorage = false
            
        case "REL":
            enableCardType = 0
            deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds"
            if version != isLaunchVersionFastRel {
                isTestCardEnabled = false
                isLaunchVersionFastRel = version
                firstLook()
            }
            cardItemsStore.cardItems = relCards
            adDebug = false
            isDebugStorage = false
            
        case .none:break
        case .some(_):break
        }
        
        #if !targetEnvironment(macCatalyst)
        if adDebug {
            NativeAdUnitIDValue = dev_NativeAdUnitID
            BannerUnitIDValue = dev_BannerUnitID
        } else {
            NativeAdUnitIDValue = NativeUnitID
            BannerUnitIDValue = bannerUnitID
        }
        #endif
        
        CloudSyncSettings.setEnabled(isCloudSyncEnabled)
        
        
        ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in })
    }
    
    func firstLook() {
        versionFirstLook = true
    }
}

#Preview {
    ContentView()
}
