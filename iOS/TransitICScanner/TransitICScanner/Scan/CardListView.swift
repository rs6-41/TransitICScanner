import SwiftUI
import CoreNFC

struct CardList: View {
    @State private var searchText = ""
    @EnvironmentObject var getCountry: GetCountry
    @EnvironmentObject var debug: DebugModel
    @EnvironmentObject var store: CardItemsStore
    
    @State var currentCountryItems: [CardInfo] = []
    @State var otherCountryItems: [CardInfo] = []
    
    @AppStorage("sort") var sort:SortType = .name_ascend
    
    @State var isDisplayScrapingForm = false
    
    var body: some View {
        NavigationStack {
            List {
                if debug.isDisplay {
                    VStack(alignment:.leading) {
                        Toggle("DEBUG MODE", isOn: $debug.isDisplay)
                            .bold()
                            .foregroundStyle(Color.red)
                        HStack(spacing:3) {
                            Text(LocalizedStringKey("cardList.nowLocate"))
                            Text(": ")
                            Text("\(getCountry.countryCode ?? "nil")")
                        }
                    }
                }
                
                
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
                        VStack(alignment:.leading) {
                            CardListRow(item: item)
                        }
                    }
                } header: {
                    HStack {
                        if !currentCountryItems.isEmpty {
                            Text(LocalizedStringKey("cardList.otherLocate"))
                        } else {
                            Text(LocalizedStringKey("cardList.allCards"))
                        }
                        Spacer()
                        Picker("", selection: $sort) {
                            ForEach(SortType.allCases, id: \.self) { item in
                                Text(LocalizedStringKey(item.rawValue))
                            }
                        }
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
            updateList()
        }
        .onChange(of:getCountry.countryCode) {
            updateList()
        }
        .onChange(of:sort) {
            updateList()
        }
        .onChange(of:searchText) {
            search()
        }
    }
    
    func updateList() {
        getCurrentItems()
        getOtherCountryItems(sort:sort)
    }
    
    func getCurrentItems() {
        let allItems = store.cardItems
        if let currentCode = getCountry.countryCode {
            currentCountryItems = allItems.filter {
                $0.countryCode.contains(currentCode)
            }
        } else {
            currentCountryItems =  []
        }
    }
    
    func getOtherCountryItems(sort:SortType) {
        let allItems = store.cardItems
        if let currentCode = getCountry.countryCode {
            let items = allItems.filter {
                !$0.countryCode.contains(currentCode)
            }
            otherCountryItems = sortItems(sort:sort,items:items)
        } else {
            otherCountryItems = sortItems(sort:sort,items:allItems)
        }
    }
    
    func sortItems(sort: SortType, items: [CardInfo]) -> [CardInfo] {
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
    
    func search() {
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
enum SortType:String,CaseIterable {
    case name_ascend = "cardList.sort.name_ascend"
    case name_descend = "cardList.sort.name_descend"
    
    case locate_ascend = "cardList.sort.locate_ascend"
    case locate_descend = "cardList.sort.locate_descend"
}

struct CardListRow: View {
    let item: CardInfo
    @State var isFormDisplay = false
    @EnvironmentObject var debug: DebugModel
    
    var body: some View {
        VStack(alignment:.leading) {
            switch item.scanOption.scanType {
            case .nfc:
                ScanningButton(item: item)
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
                CardListItemDebugView(item:item)
            }
        }
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
                    
                    Text(LocalizedStringKey(item.area.rawValue))
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
