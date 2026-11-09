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
    let appEnvironment = AppEnvironment.current

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

    @AppStorage("firstPermission") var firstPermission = true

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isDuoOpen = false
    @ObservedObject private var storageError = StorageErrorNotifier.shared
    @State private var isStorageAlert =
        SavedDataModelContainer.startupState != .normal
    private var showsSidebar: Bool {
        #if targetEnvironment(macCatalyst)
        true
        #else
        horizontalSizeClass == .regular
        #endif
    }

    private var usesPhoneNavigationBarPicker: Bool {
        #if targetEnvironment(macCatalyst)
        false
        #else
        isDuoOpen
        #endif
    }

    private var scanTabIcon: String {
        if UIDevice.current.userInterfaceIdiom == .phone {
            "iphone.radiowaves.left.and.right"
        } else {
            "wave.3.right.circle"
        }
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab(LocalizedStringKey("tab.scan"), systemImage: scanTabIcon, value: 0) {
                CardList(deleteAds: $deleteAds, smartCardManager: smartCardManager)
            }
            Tab(LocalizedStringKey("tab.history"), systemImage: "tram.card", value: 1) {
                SavedListView(deleteAds: $deleteAds)
            }

            if appEnvironment == .dev {
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
            if showsSidebar && !usesPhoneNavigationBarPicker {
                VStack(alignment: .leading, spacing: 10) {
                    #if targetEnvironment(macCatalyst)
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 1)
                    #endif
                    ScanReaderPicker(
                        manager: smartCardManager,
                        showsIconAndText: true
                    )
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .iPhoneDuoHinge(value: $isDuoOpen)
        .task {
            smartCardManager.start()
        }
        .alert(
            LocalizedStringKey("error.storage.title"),
            isPresented: $isStorageAlert
        ) {
            Button(LocalizedStringKey("ok")) {}
        } message: {
            Text(
                LocalizedStringKey(
                    SavedDataModelContainer.startupState == .localOnly
                        ? "error.storage.localOnly.message"
                        : "error.storage.inMemory.message"
                ))
        }
        .alert(
            LocalizedStringKey("error.storage.save.title"),
            isPresented: $storageError.isPresented
        ) {
            Button(LocalizedStringKey("ok")) {}
        } message: {
            Text(storageError.message)
        }
        .task(id: deleteAdsPurchaseID) {
            // 返金・他の端末での購入などを広告表示に反映する
            PurchaseManager.shared.startObservingTransactions()
            await PurchaseManager.shared.refreshEntitlement()
        }
        .task(id: firstPermission) {
            // 初回の権限説明(ATT を含む)が終わってから広告の同意を取得する
            if !firstPermission {
                await AdConsentManager.shared.gatherConsent()
            }
        }
        .sheet(isPresented: $firstPermission) {
            PermissionModalView(isPresented: $firstPermission)
                .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $ads.isDeleteAdsSheet) {
            NavigationStack {
                List {
                    SettingAdsPurchase(
                        deleteAdsPurchaseID: $deleteAdsPurchaseID, purchaseAlertTitle: $ads.purchaseAlertTitle,
                        purchaseAlertMessage: $ads.purchaseAlertMessage, isPurchaseAlert: $ads.isPurchaseAlert,
                        deleteAds: $deleteAds
                    )
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
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            dismiss()
                            ads.isDeleteAdsSheet = false
                        }) {
                            Image(systemName: "xmark")
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
        case .dev:
            deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds.test"
            cardItemsStore.cardItems = devCards + featureCards + relCards
            adDebug = true

        case .beta:
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

        case .rel:
            enableCardType = 0
            deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds"
            if version != isLaunchVersionFastRel {
                isTestCardEnabled = false
                isLaunchVersionFastRel = version
                firstLook()
            }
            cardItemsStore.cardItems = relCards
            adDebug = false

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

        // ATT の許可は初回起動時の説明画面(PermissionModalView)から求める。
        // 説明画面を完了済みでまだ未決定の場合（説明画面に ATT がなかった旧バージョンからの更新など）のみここで求める。
        if !firstPermission,
            ATTrackingManager.trackingAuthorizationStatus == .notDetermined
        {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }

    func firstLook() {
        versionFirstLook = true
    }
}

#Preview {
    ContentView(smartCardManager: SmartCardManager())
}
