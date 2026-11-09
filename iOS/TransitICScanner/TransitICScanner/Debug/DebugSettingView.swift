import SwiftUI
import Combine
import SwiftData

final class DebugModel: ObservableObject {
    @Published var isDisplay: Bool = false
    @Published var isDebugAds: Bool = false
}

struct DebugSettingView: View {
    @Binding var deleteAdsPurchaseID:String
    @Binding var deleteAds:Bool
    private let devLocates: [(name: String, code: String)] = [
        ("cardList.area.jp", "jp")
        ,("cardList.area.cn", "cn")
        ,("cardList.area.hk", "hk")
        ,("cardList.area.mo", "mo")
        ,("cardList.area.tw", "tw")
        ,("cardList.area.kr", "kr")
        ,("cardList.area.kp", "kp")
        ,("cardList.area.us", "us")
        ,("unknown", "unknown")
    ]
    @State var devLocate = ""
    
    @State var isLoading = false
    
    @EnvironmentObject var getCountry: GetCountry
    @EnvironmentObject var debug: DebugModel
    @EnvironmentObject var store: CardItemsStore
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("enableCardType") var enableCardType = 0
    
    @State var alertTitle:String = ""
    @State var alertMessage:String = ""
    @State var isAlert:Bool = false
    
    @State var isDummyCardForm = false
    
    @AppStorage("adDebug") var adDebug = false
    
    @AppStorage(StorageConfig.debugStorageKey, store: StorageConfig.sharedSettings)
    var isDebugStorage = false
    @AppStorage("firstPermission") var firstPermission = true
    
    var body: some View {
        ZStack {
            List {
                Section() {
                    Toggle(isOn: $debug.isDisplay) {
                        Text(LocalizedStringKey("setting.debug.isdisplay"))
                    }
                }
                
                Section(header: Text(LocalizedStringKey("setting.debug.scanlist.title"))) {
                    
                    NavigationLink(destination: EnableTestCardsView()) {
                        HStack {
                            Text(LocalizedStringKey("setting.debug.enableTestCards"))
                            Spacer()
                            Text(LocalizedStringKey("setting.debug.enableTestCards.count:\(store.cardItems.count)"))
                                .foregroundStyle(Color.gray)
                        }
                    }
                    Picker("setting.debug.scanlist.enableCardType", selection: $enableCardType) {
                        Text("setting.debug.scanlist.enableCardType.optional").tag(0)
                        Text("setting.debug.scanlist.enableCardType.rel").tag(1)
                        Text("setting.debug.scanlist.enableCardType.feature").tag(2)
                        Text("setting.debug.scanlist.enableCardType.dev").tag(3)
                    }
                    .onChange(of:enableCardType) {
                        switch enableCardType {
                            case 1:store.cardItems = relCards
                            case 2:store.cardItems = featureCards + relCards
                            case 3:store.cardItems = devCards + featureCards + relCards
                            default:break
                        }
                    }
                }
                Section() {
                    Picker(
                        LocalizedStringKey("setting.debug.locate"),
                        selection: $devLocate
                    ) {
                        Text(LocalizedStringKey("setting.debug.locate.reset"))
                            .tag("")
                        
                        ForEach(devLocates, id: \.code) { locate in
                            Text(LocalizedStringKey(locate.name))
                                .tag(locate.code)
                        }
                    }
                    .onChange(of: devLocate) {
                        if devLocate.isEmpty {
                            getCountry.resetDebug()
                            getCountry.start()
                        } else {
                            getCountry.debug(country: devLocate)
                        }
                    }
                }
                
                Section() {
                        Toggle(isOn: $isDebugStorage) {
                            Text(LocalizedStringKey("setting.debug.result.debugStorage"))
                        }
                    
                } header: {
                    Text(LocalizedStringKey("setting.debug.result.title"))
                } footer: {
                    Text(LocalizedStringKey("setting.debug.result.debugStorage.description"))
                }
                Section {
                    Button(action: {
                        isDummyCardForm = true
                    }) {
                        Text(LocalizedStringKey("setting.debug.result.dummyCard"))
                    }
                    
                    Button(action: {
                        Task { @MainActor in
                            isLoading = true
                            for card in cardItemsStore.cardItems {
                                let result = getResultSample(model: card)
                                saveAction(result: result)
                                try? await Task.sleep(nanoseconds: 200_000_000)
                            }
                            alertTitle = String(localized: "setting.debug.result.demoCard")
                            alertMessage = String(localized: "done")
                            isAlert = true
                            isLoading = false
                        }
                    }) {
                        Text(LocalizedStringKey("setting.debug.result.demoCard"))
                    }
                }
                
                Section(header: Text(LocalizedStringKey("setting.debug.permission"))) {
                    Toggle(isOn: $firstPermission) {
                        Text(LocalizedStringKey("setting.debug.permission.isDisplay"))
                    }
                }
                
                #if !targetEnvironment(macCatalyst)
                Section(header: Text(LocalizedStringKey("setting.debug.ad"))) {
                    Toggle(isOn: $adDebug) {
                        Text(LocalizedStringKey("setting.debug.ad.debugMode"))
                    }
                    .onChange(of:adDebug) {
                        if adDebug {
                            NativeAdUnitIDValue = dev_NativeAdUnitID
                            BannerUnitIDValue = dev_BannerUnitID
                        } else {
                            NativeAdUnitIDValue = NativeUnitID
                            BannerUnitIDValue = bannerUnitID
                        }
                    }
                }
                #endif
                
                Section(header: Text(LocalizedStringKey("setting.debug.purchase.title"))) {
                    Toggle(isOn: $deleteAds) {
                        Text(LocalizedStringKey("setting.debug.ads"))
                    }
                    Picker(LocalizedStringKey("setting.debug.ads.id"), selection: $deleteAdsPurchaseID) {
                        Text(LocalizedStringKey("setting.debug.ads.id.test")).tag("com.rs6apps.TransitICScanner.deleteAds.test")
                        Text(LocalizedStringKey("setting.debug.ads.id.rel")).tag("com.rs6apps.TransitICScanner.deleteAds")
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("setting.debug"))
            .navigationBarTitleDisplayMode(.inline)
            
            .sheet(isPresented: $isDummyCardForm) {
                NavigationStack {
                    DummyCardFormView(deleteAds: $deleteAds)
                }
            }
            
            .alert(alertTitle, isPresented: $isAlert) {
                Button(LocalizedStringKey("ok")) {
                    alertTitle = ""
                    alertMessage = ""
                    isAlert = false
                }
            } message: {
                Text(alertMessage)
            }
            
            
            .contentMargins(.top, 10)
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView(String("Loading..."))
                    .padding()
                    .background(.background)
                    .cornerRadius(10)
            }
        }
    }
    
    private func saveAction(result:Result) {
        do {
            try ResultSave.save(
                result,
                in: modelContext
            )
            print("Resultの保存に成功しました")
        } catch {
            print("Resultの保存に失敗しました: \(error)")
        }
    }
}
