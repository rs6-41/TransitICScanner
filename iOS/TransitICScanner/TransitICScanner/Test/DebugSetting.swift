import SwiftUI
import Combine

final class DebugModel: ObservableObject {
    @Published var isDisplay: Bool = false
}

struct DebugSetting: View {
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
    @EnvironmentObject var getCountry: GetCountry
    @EnvironmentObject var debug: DebugModel
    @EnvironmentObject var store: CardItemsStore
    
    var body: some View {
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
    }
}
