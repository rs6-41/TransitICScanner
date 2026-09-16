import SwiftUI
import Combine


struct ContentView: View {
    @State var tab: Int = 0
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
            SettingView()
                .tag(2)
                .toolbarBackground(.visible, for: .tabBar)
                .tabItem {
                    Label(String(localized:"tab.setting"), systemImage: "info.circle.fill")
                }
             
        }
    }
}

#Preview {
    ContentView()
}
