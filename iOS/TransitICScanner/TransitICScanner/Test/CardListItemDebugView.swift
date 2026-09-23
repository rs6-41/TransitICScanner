import SwiftUI

struct CardListItemDebugView: View {
    var item:CardInfo
    @State var searchWordsLocalized = ""
    
    var body: some View {
        HStack {
            VStack {
                Text(String("""
                [DEBUG] ScanType: \(item.scanOption.scanType)
                [DEBUG] area.sortName: \(Localize(item.area.sortName()))
                [DEBUG] searchWords: \(searchWordsLocalized)
                """))
            }
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(Color.red)
        .onAppear() {
            for i in item.searchWords {
                searchWordsLocalized += ("\"" + Localize(i) + "\",")
            }
        }
    }
}
