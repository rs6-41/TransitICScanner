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

    @ObservedObject var smartCardManager: SmartCardManager
    
    
    @AppStorage("isDebugStorage") var isDebugStorage = false
    
    @AppStorage("firstPermission") var firstPermission = true
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var showsSidebar: Bool {
        #if targetEnvironment(macCatalyst)
        true
        #else
        horizontalSizeClass == .regular
        #endif
    }
    
    var body: some View {
        TabView(selection: $tab) {
            Tab(LocalizedStringKey("tab.scan"), systemImage: "iphone.radiowaves.left.and.right", value: 0) {
                CardList(deleteAds: $deleteAds, smartCardManager: smartCardManager)
            }
            Tab(LocalizedStringKey("tab.history"), systemImage: "tram.card", value: 1) {
                NavigationStack {
                    SavedListView(deleteAds: $deleteAds)
                }
            }

            if appEnvironment == "DEV" {
                Tab(LocalizedStringKey("tab.tool"), systemImage: "latch.2.case.fill", value: 2) {
                    NavigationStack {
                        NFCToolView(deleteAds: $deleteAds)
                    }
                }
            }

            Tab(LocalizedStringKey("tab.setting"), systemImage: "gearshape", value: 3) {
                NavigationStack {
                    SettingView(
                        deleteAds: $deleteAds,
                        deleteAdsPurchaseID: $deleteAdsPurchaseID,
                        isCloudSyncEnabled: $isCloudSyncEnabled
                    )
                }
            }
        }
        .navigationTitle(LocalizedStringKey("appName"))
        .tabViewSidebarBottomBar {
            if showsSidebar {
                    HStack {
                        ScanReaderPicker(
                            manager: smartCardManager,
                            showsIconAndText: true
                        )
                        .lineLimit(1)
                        Spacer()
                    }
                .padding(.horizontal)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
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
    ContentView(smartCardManager: SmartCardManager())
}
