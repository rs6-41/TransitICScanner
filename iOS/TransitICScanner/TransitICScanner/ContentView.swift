import SwiftUI
import Combine


struct ContentView: View {
    @State var tab: Int = 0
    @State var deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds"
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
    func setup() {
        #if DEBUG
            cardItemsStore.cardItems = devCards
            deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds.test"
        #else
            cardItemsStore.cardItems = relCards
            deleteAdsPurchaseID = "com.rs6apps.TransitICScanner.deleteAds"
        #endif
    }
}

#Preview {
    ContentView()
}
