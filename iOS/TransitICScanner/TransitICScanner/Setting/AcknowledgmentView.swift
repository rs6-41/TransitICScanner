import SwiftUI

struct AcknowledgmentView: View {
    var body: some View {
        List {
            NavigationLink(destination: TRView()) {
                Text(LocalizedStringKey("setting.acknowledgment.cardtr"))
            }
        }
        .navigationTitle(LocalizedStringKey("setting.acknowledgment"))
        
        .listSectionSpacing(.compact)
                    .contentMargins(.top, 3)
                    .environment(\.defaultMinListRowHeight, 1)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                        .zero
                    }
    }
}

//カード商標
struct TRView: View {
    let trItems:[String] = ["apple","google","sony"]
    var body: some View {
        List {
            Section(header:Text("setting.acknowledgment.tr.card")) {
                ForEach(cardItems, id: \.logo) { item in
                    NavigationLink(destination: Acknowledgment(title:item.name,text:"setting.acknowledgment." + item.scanOption.name)) {
                        Text(LocalizedStringKey(item.name))
                    }
                }
            }
            Section(header:Text("setting.acknowledgment.tr.other"),footer: Text("setting.acknowledgment.cardtr.description")) {
                ForEach(trItems, id: \.self) { trItem in
                    NavigationLink(destination: Acknowledgment(title:"setting.acknowledgment." + trItem + ".title",text:"setting.acknowledgment." + trItem)) {
                        Text(LocalizedStringKey("setting.acknowledgment." + trItem + ".title"))
                    }
                }
            }
        }
        .navigationTitle(LocalizedStringKey("setting.acknowledgment.cardtr"))
        
        .listSectionSpacing(.compact)
                    .contentMargins(.top, 3)
                    .environment(\.defaultMinListRowHeight, 1)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                        .zero
                    }
    }
}


struct Acknowledgment: View {
    var title: String
    var text: String
    var body: some View {
        ScrollView {
            HStack {
                Text(LocalizedStringKey(text))
                    .foregroundStyle(Color.gray)
                    .navigationTitle(LocalizedStringKey(title))
            }
            .padding()
        }
        .frame(maxWidth:.infinity,alignment:.leading)
    }
}

#Preview {
    AcknowledgmentView()
}
