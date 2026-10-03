import SwiftUI

struct NFCToolView: View {
    @Binding var deleteAds:Bool
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: NFCLogView()) {
                    Text(LocalizedStringKey("tool.fullLog"))
                }
                
            }
            .navigationTitle(LocalizedStringKey("tab.tool"))
        }
    }
}
