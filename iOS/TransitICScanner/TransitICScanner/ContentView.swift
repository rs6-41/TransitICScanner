import SwiftUI
import Combine


struct ContentView: View {
    @State var tab: Int = 0
    @State var deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds"
    @AppStorage("enableCardType") var enableCardType = 0
    @AppStorage("testCardEnabled") var isTestCardEnabled = false
    
    @AppStorage("isLaunchVersionFastBeta") var isLaunchVersionFastBeta = ""
    @AppStorage("isLaunchVersionFastRel") var isLaunchVersionFastRel = ""
    
    let appEnvironment = Bundle.main.object(
        forInfoDictionaryKey: "AppEnvironment"
    ) as? String
    
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    
    @State var versionFirstLook = false
    
    var body: some View {
        TabView(selection: $tab) {
            CardList()
                .tag(0)
                .toolbarBackground(.visible, for: .tabBar)
                .tabItem {
                    Label(String(localized:"tab.scan"), systemImage: "iphone.radiowaves.left.and.right")
                }
            SavedListView()
                .tag(1)
                .toolbarBackground(.visible, for: .tabBar)
                .tabItem {
                    Label(String(localized:"tab.history"), systemImage: "tram.card")
                }
            SettingView(deleteAdsPurchaseID: $deleteAdsPurchaseID)
                .tag(2)
                .toolbarBackground(.visible, for: .tabBar)
                .tabItem {
                    Label(String(localized:"tab.setting"), systemImage: "gearshape")
                }
             
        }
        
        .onAppear() {
            setup()
        }
    }
    private func setup() {
        switch appEnvironment {
        case "DEV":
            deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds.test"
            cardItemsStore.cardItems = devCards + featureCards + relCards
            
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
            
        case "REL":
            enableCardType = 0
            deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds"
            if version != isLaunchVersionFastRel {
                isTestCardEnabled = false
                isLaunchVersionFastRel = version
                firstLook()
            }
            cardItemsStore.cardItems = relCards
            
        case .none:break
        case .some(_):break
        }
    }
    
    func firstLook() {
        versionFirstLook = true
    }
}

#Preview {
    ContentView()
}
