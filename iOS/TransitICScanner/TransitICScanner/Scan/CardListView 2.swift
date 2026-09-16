import SwiftUI
import CoreNFC

struct CardList: View {
    @StateObject private var getCountry = GetCountry()
    @State private var searchText = ""
    
    private var filteredCardItems: [CardInfo] {
        guard !searchText.isEmpty else {
            return cardItems
        }
        
        return cardItems.filter { item in
            let localizedName = String(
                localized: String.LocalizationValue(item.name)
            )
            
            if localizedName.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            return item.searchWords.contains { key in
                let localizedWord = String(
                    localized: String.LocalizationValue(key)
                )
                
                return localizedWord.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var currentCountryItems: [CardInfo] {
        guard let currentCode = getCountry.countryCode else {
            return []
        }

        return filteredCardItems.filter {
            $0.countryCode.contains(currentCode)
        }
    }

    private var otherCountryItems: [CardInfo] {
        guard let currentCode = getCountry.countryCode else {
            return filteredCardItems
        }

        return filteredCardItems.filter {
            !$0.countryCode.contains(currentCode)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !currentCountryItems.isEmpty {
                    Section {
                        ForEach(currentCountryItems, id: \.logo) { item in
                            CardListRow(item: item)
                        }
                    } header: {
                        Text(LocalizedStringKey("cardList.nowLocate"))
                    }
                }
                
                Section {
                    ForEach(otherCountryItems, id: \.logo) { item in
                        CardListRow(item: item)
                    }
                } header: {
                    if !currentCountryItems.isEmpty {
                        Text(LocalizedStringKey("cardList.otherLocate"))
                    }
                } footer: {
                    Text(LocalizedStringKey("cardList.description"))
                }
            }
            .searchable(
                text: $searchText,
                prompt: Text(LocalizedStringKey("search"))
            )
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                .zero
            }
            .navigationTitle(LocalizedStringKey("cardList.title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Result.self) { result in
                ResultView(
                    result: result,
                    scandata: true,
                    saveListID: .constant(UUID())
                )
            }
        }
        .onAppear {
            getCountry.start()
        }
    }
}

struct CardListRow: View {
    let item: CardInfo
    
    var body: some View {
        ScanningButton(item: item)
    }
}

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
                    case .scraping:
                        Image(systemName: "creditcard.and.numbers")
                    }
                    
                    Text(LocalizedStringKey(item.area))
                        .bold()
                    
                    Spacer()
                }
                .foregroundStyle(Color.gray)
                .font(.caption)
                
                Text(LocalizedStringKey(item.name))
                
                if let description = item.description {
                    Text(LocalizedStringKey(description))
                        .foregroundStyle(Color.gray)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            if item.infomation != nil {
                Button(action: {
                    isCardInfoView.toggle()
                }) {
                    Image(systemName: "questionmark.circle")
                        .imageScale(.large)
                }
                .sheet(isPresented: $isCardInfoView) {
                    NavigationStack {
                        ScrollView {
                            item.infomation
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CardList()
}
