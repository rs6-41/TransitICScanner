import SwiftUI

struct DebugSetting: View {
    @Binding var deleteAdsPurchaseID:String
    @Binding var deleteAds:Bool
    var body: some View {
        Section(header:Text(LocalizedStringKey("setting.debug"))) {
            NavigationLink(destination: EnableTestCardsView()) {
                Text(LocalizedStringKey("setting.debug.enableTestCards"))
            }
            
            Toggle(isOn: $deleteAds) {
                Text(LocalizedStringKey("setting.debug.ads"))
            }
            Picker(LocalizedStringKey("setting.debug.ads.id"), selection: $deleteAdsPurchaseID) {
                Text(LocalizedStringKey("setting.debug.ads.id.test")).tag("com.rs6apps.TransitICScanner.deleteAds.test")
                Text(LocalizedStringKey("setting.debug.ads.id.rel")).tag("com.rs6apps.TransitICScanner.deleteAds")
            }
        }
    }
}
