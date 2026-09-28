import SwiftUI
import CoreNFC

struct CardList: View {
    @State private var searchText = ""
    @EnvironmentObject var getCountry: GetCountry
    @EnvironmentObject var debug: DebugModel
    @EnvironmentObject var store: CardItemsStore
    
    @State var currentCountryItems: [CardInfo] = []
    @State var otherCountryItems: [CardInfo] = []
    @State private var administrativeArea: String?
    
    @AppStorage("sort") var sort: SortType = .locate_ascend
    
    @State var isDisplayScrapingForm = false
    @Binding var deleteAds: Bool
    
    var body: some View {
        NavigationStack {
            List {
                ListAdView(deleteAds: $deleteAds)
                
                if debug.isDisplay {
                    VStack(alignment: .leading) {
                        Toggle(String("DEBUG MODE"), isOn: $debug.isDisplay)
                            .bold()
                            .foregroundStyle(Color.red)
                        
                        HStack(spacing: 3) {
                            Text(LocalizedStringKey("cardList.nowLocate"))
                            Text(verbatim: ": ")
                            Text(verbatim: getCountry.countryCode ?? "nil")
                            
                            if let administrativeArea {
                                Text(verbatim: " \(administrativeArea)")
                            }
                        }
                    }
                }
                
                if !currentCountryItems.isEmpty {
                    Section {
                        ForEach(currentCountryItems, id: \.logo) { item in
                            CardListRow(item: item, deleteAds: $deleteAds)
                        }
                    } header: {
                        HStack(spacing: 4) {
                            Text(LocalizedStringKey("cardList.nowLocate"))
                        }
                    }
                }
                
                Section {
                    ForEach(otherCountryItems, id: \.logo) { item in
                        VStack(alignment: .leading) {
                            CardListRow(item: item, deleteAds: $deleteAds)
                        }
                    }
                } header: {
                    if searchText.isEmpty {
                        HStack {
                            if !currentCountryItems.isEmpty {
                                Text(LocalizedStringKey("cardList.otherLocate"))
                            } else {
                                Text(LocalizedStringKey("cardList.allCards"))
                            }
                            
                            Spacer()
                            
                            Picker(String(""), selection: $sort) {
                                ForEach(SortType.allCases, id: \.self) { item in
                                    Text(LocalizedStringKey(item.rawValue))
                                }
                            }
                            .buttonStyle(.glass)
                        }
                    } else {
                        Text(LocalizedStringKey("cardList.searchResults"))
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
                    saveListID: .constant(UUID()),
                    deleteAds: $deleteAds
                )
            }
        }
        .onAppear {
            getCountry.start()
            updateList()
            
            Task {
                administrativeArea = await getCountry.fetchAdministrativeArea()
                updateList()
            }
        }
        .onChange(of: getCountry.countryCode) {
            updateList()
            
            Task {
                administrativeArea = await getCountry.fetchAdministrativeArea()
                updateList()
            }
        }
        .onChange(of: sort) {
            updateList()
        }
        .onChange(of: searchText) {
            search()
        }
    }
    
    private func updateList() {
        getCurrentItems()
        getOtherCountryItems(sort: sort)
    }
    
    private func getCurrentItems() {
        currentCountryItems = store.cardItems.filter {
            isCurrentLocation(item: $0)
        }
    }
    
    private func getOtherCountryItems(sort: SortType) {
        let items = store.cardItems.filter {
            !isCurrentLocation(item: $0)
        }
        
        otherCountryItems = sortItems(sort: sort, items: items)
    }
    
    private func isCurrentLocation(item: CardInfo) -> Bool {
        guard let currentCode = getCountry.countryCode else {
            return false
        }
        
        guard item.countryCode.contains(currentCode) else {
            return false
        }
        
        guard let prefectures = item.prefectures else {
            return true
        }
        
        guard let administrativeArea else {
            return false
        }
        
        return prefectures.contains(administrativeArea)
    }
    
    private func sortItems(sort: SortType, items: [CardInfo]) -> [CardInfo] {
        items.sorted {
            switch sort {
            case .name_ascend:
                Localize($0.sortName).localizedStandardCompare(
                    Localize($1.sortName)
                ) == .orderedAscending
                
            case .name_descend:
                Localize($0.sortName).localizedStandardCompare(
                    Localize($1.sortName)
                ) == .orderedDescending
                
            case .locate_ascend:
                Localize($0.area.sortName()).localizedStandardCompare(
                    Localize($1.area.sortName())
                ) == .orderedAscending
                
            case .locate_descend:
                Localize($0.area.sortName()).localizedStandardCompare(
                    Localize($1.area.sortName())
                ) == .orderedDescending
            }
        }
    }
    
    private func search() {
        if searchText.isEmpty {
            updateList()
        } else {
            currentCountryItems = []
            
            otherCountryItems = store.cardItems.filter { item in
                let localizedName = String(
                    localized: String.LocalizationValue(item.name)
                )
                
                if localizedName.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                let localizedArea = String(
                    localized: String.LocalizationValue(item.area.rawValue)
                )
                
                if localizedArea.localizedCaseInsensitiveContains(searchText) {
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
    }
}


// リストのソート選択
enum SortType: String, CaseIterable {
    case name_ascend = "cardList.sort.name_ascend"
    case name_descend = "cardList.sort.name_descend"
    
    case locate_ascend = "cardList.sort.locate_ascend"
    case locate_descend = "cardList.sort.locate_descend"
}

struct CardListRow: View {
    let item: CardInfo
    @State var isFormDisplay = false
    @EnvironmentObject var debug: DebugModel
    @Binding var deleteAds: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            switch item.scanOption.scanType {
            case .nfc:
                ScanningButton(item: item, deleteAds: $deleteAds)
                
            case .scraping:
                if let view = item.scanOption.scrapingView {
                    Button(action: {
                        isFormDisplay = true
                    }) {
                        ListButtonInner(item: item)
                    }
                    .sheet(isPresented: $isFormDisplay) {
                        view()
                    }
                }
            }
            
            if debug.isDisplay {
                CardListItemDebugView(item: item)
            }
        }
    }
}

#Preview {
    CardList(deleteAds: .constant(false))
}
