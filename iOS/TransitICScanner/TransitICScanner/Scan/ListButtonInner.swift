import SwiftUI

struct ListButtonInner: View {
    let item: CardInfo
    @State var isCardInfoView = false
    
    var body: some View {
        HStack {
            CardImage(name: item.logo)
            
            VStack(alignment: .leading) {
                HStack(spacing: 3) {
                    switch item.scanOption.scanType {
                    case .nfc:
                        Image(systemName: "wave.3.right")
                            .imageScale(.small)
                    case .scraping:
                        Image(systemName: "creditcard.and.numbers")
                            .imageScale(.small)
                    }
                    Text(LocalizedStringKey(item.name))
                        .fontWeight(.semibold)
                }
                
                VStack(alignment:.leading, spacing: 0) {
                    HStack(spacing: 2) {
                        Text(LocalizedStringKey(item.area.rawValue))
                            .fontWeight(.semibold)
                        if let prefectures = item.prefectures {
                            ForEach(prefectures, id: \.self) { prefecture in
                                Text(LocalizedStringKey("locate.prefecture." + prefecture))
                                if prefecture != prefectures.last {
                                    Text(String(", "))
                                }
                            }
                        }
                    }
                    
                    if let description = item.description {
                        Text(LocalizedStringKey(description))
                    }
                }
                .foregroundStyle(Color.gray)
                .font(.caption)
            }
            
            Spacer()
            
            if item.infomation != nil {
                Button(action: {
                    isCardInfoView.toggle()
                }) {
                    Image(systemName: "questionmark.circle")
                        .imageScale(.large)
                }
                .foregroundStyle(Color.accentColor)
                .sheet(isPresented: $isCardInfoView) {
                    NavigationStack {
                        ScrollView {
                            item.infomation
                        }
                    }
                }
            }
        }
        
        .foregroundStyle(Color.primary)
    }
}
