import SwiftUI

struct SettingFeatureView: View {
    @AppStorage("testCardEnabled") var isTestCardEnabled = false
    
    @EnvironmentObject var store: CardItemsStore
    var body: some View {
        List {
            Section(footer:Text(LocalizedStringKey("setting.feature.card.description"))) {
                Toggle(isOn: $isTestCardEnabled) {
                    SquareIcon(text:"setting.feature.card", systemImage: "tram.card",color:Color.purple)
                }
                .onChange(of:isTestCardEnabled) {
                    if isTestCardEnabled {
                        store.cardItems = featureCards
                    } else {
                        store.cardItems = relCards
                    }
                }
            }
            Section(footer:Text(LocalizedStringKey("setting.feature.description"))) {}
        }
        .navigationTitle(LocalizedStringKey("setting.feature"))
        
        .contentMargins(.top, 10)
    }
}
