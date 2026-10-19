import SwiftUI
import CoreNFC
import Combine

struct CardList: View {
    @State private var searchText = ""
    @EnvironmentObject var getCountry: GetCountry
    @EnvironmentObject var debug: DebugModel
    @EnvironmentObject var store: CardItemsStore
    
    @State var currentCountryItems: [CardInfo] = []
    @State var searchItems: [CardInfo] = []
    @State private var administrativeArea: String?
    
    
    @State var isDisplayScrapingForm = false
    @Binding var deleteAds: Bool
    @ObservedObject var smartCardManager: SmartCardManager
    
    @State private var scrollOffsetY: CGFloat = 0
    @State private var searchBarOffsetY: CGFloat = 0
    @State var searchBarHight: CGFloat = 0
    @State var isSearchFocused:Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section() {
                    HStack {
                        Color.white.opacity(0.000001)
                            .onTapGesture {
                                isSearchFocused = true
                            }
                        if isSearchFocused {
                            Color.white.opacity(0.000001)
                                .onTapGesture {
                                    isSearchFocused = false
                                    searchText = ""
                                }
                                .frame(width:40,height: 40)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                
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
                        Text(LocalizedStringKey("cardList.nowLocate"))
                    }
                }
                
                
                if searchText == "" {
                    Section {
                        ForEach(regionLists, id: \.self) { list in
                            let filtFirstItem = store.cardItems.filter {
                                $0.regionOption == nil &&
                                $0.area.region() == list.first
                            } +
                            store.cardItems.filter {
                                $0.regionOption == list.first
                            }
                            
                            if filtFirstItem.count != 0 {
                                if let second = list.second {
                                    NavigationLink(destination: CardRegionView(
                                        smartCardManager:smartCardManager,
                                        items: filtFirstItem.filter {
                                            $0.scanOption.scanType != .external
                                        },
                                        subItems: store.cardItems.filter {
                                            $0.regionOption == nil &&
                                            $0.area.region() == second &&
                                            $0.scanOption.scanType != .external
                                        },
                                        externalItems: filtFirstItem.filter {
                                            $0.scanOption.scanType == .external
                                        },
                                        deleteAds: $deleteAds
                                    )) {
                                        SquareIcon(text:LocalizedStringKey(list.first.name()),systemImage:list.first.icon(),color:Color.blue)
                                    }
                                } else {
                                    NavigationLink(destination: CardRegionView(
                                        smartCardManager:smartCardManager,
                                        items: filtFirstItem.filter {
                                            $0.scanOption.scanType != .external
                                        },
                                        externalItems: filtFirstItem.filter {
                                            $0.scanOption.scanType == .external
                                        },
                                        deleteAds: $deleteAds
                                    )) {
                                        SquareIcon(text:LocalizedStringKey(list.first.name()),systemImage:list.first.icon(),color:Color.blue)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text(LocalizedStringKey("cardList.otherLocate"))
                    } footer: {
                        Text(LocalizedStringKey("cardList.description"))
                    }
                } else {
                    Section() {
                        ForEach(searchItems, id: \.logo) { item in
                            CardListRow(item: item, deleteAds: $deleteAds)
                        }
                    } header: {
                        if searchText.isEmpty {
                            HStack {
                                Text(LocalizedStringKey("cardList.allCards"))
                            }
                        } else {
                            Text(LocalizedStringKey("cardList.searchResults"))
                        }
                    } footer: {
                        Text(LocalizedStringKey("cardList.description"))
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("cardList.title"))
            .toolbarTitleDisplayMode(.inlineLarge)
            
            .toolbar {
                ToolbarItem(placement: .title) {
                    Text("")
                }
                
                ToolbarItem(placement: .subtitle) {
                    HStack {
                        SearchBar(text:$searchText,isFocused: $isSearchFocused,placeholder:String(localized:"cardList.search"))
                        Button(action: {
                            withAnimation(.linear(duration: 0.3)) {
                                isSearchFocused = false
                                searchText = ""
                            }
                        }) {
                            Image(systemName:"xmark")
                                .frame(width:30,height:30)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .opacity(isSearchFocused ? 1 : 0)
                        .frame(width: isSearchFocused ? 40 : 0)
                    }
                    .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
                    .offset(y: max(0, searchBarOffsetY))
                    .zIndex(1)
                    .onGeometryChange(for: CGFloat.self, of: { proxy in
                        proxy.size.height
                    }, action: { newHeight in
                        searchBarHight = newHeight
                    })
                }
                 
            }
             
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                .zero
            }
            .navigationDestination(for: Result.self) { result in
                ResultView(
                    result: result,
                    scandata: true,
                    saveListID: .constant(UUID()),
                    deleteAds: $deleteAds
                )
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { oldVal, newVal in
            scrollOffsetY = newVal
            if scrollOffsetY < searchBarHight {
                searchBarOffsetY = -(scrollOffsetY + searchBarHight)
            } else {
                searchBarOffsetY = -scrollOffsetY
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
        .onChange(of: searchText) {
            search()
        }
    }
    
    private func updateList() {
        getCurrentItems()
    }
    
    private func getCurrentItems() {
        currentCountryItems = store.cardItems.filter {
            isCurrentLocation(item: $0)
        }
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
    
    private func search() {
        if searchText.isEmpty {
            updateList()
        } else {
            currentCountryItems = []
            
            searchItems = store.cardItems.filter { item in
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

struct CardRegionView: View {
    @ObservedObject var smartCardManager: SmartCardManager
    @State var items: [CardInfo]
    @State var subItems: [CardInfo]?
    @State var externalItems: [CardInfo]?
    @Binding var deleteAds:Bool
    @State var sort: SortType = .locate_ascend
    @State var sort2: SortType = .locate_ascend
    @State var sort3: SortType = .locate_ascend
    var body: some View {
        List {
            ListAdView(deleteAds: $deleteAds)
            Section() {
                ForEach(sortItems(sort:sort,items:items,pref:false), id: \.logo) { item in
                    CardListRow(item: item, deleteAds: $deleteAds)
                }
            } footer: {
                Text(LocalizedStringKey("cardList.description"))
            }
            if let subItems {
                if !subItems.isEmpty {
                    Section() {
                        ForEach(sortItems(sort:sort2,items:subItems,pref:true), id: \.logo) { item in
                            CardListRow(item: item, deleteAds: $deleteAds)
                        }
                    } header: {
                        HStack {
                            Text(LocalizedStringKey(subItems.first?.area.region().name() ?? ""))
                            Spacer()
                        }
                    } footer: {
                        Text(LocalizedStringKey("cardList.description"))
                    }
                }
            }
            if let externalItems {
                if !externalItems.isEmpty {
                    Section() {
                        ForEach(sortItems(sort:sort2,items:externalItems,pref:true), id: \.logo) { item in
                            CardListRow(item: item, deleteAds: $deleteAds, externalDevice:!smartCardManager.readers.isEmpty)
                        }
                    } header: {
                        VStack(alignment:.leading, spacing:5) {
                            HStack {
                                Text(LocalizedStringKey("cardList.external.title"))
                                Spacer()
                                HStack(spacing:4) {
                                    if smartCardManager.readers.isEmpty {
                                        Circle()
                                            .fill(Color.red)
                                            .stroke(Color.gray, lineWidth: 1.5)
                                            .frame(width:15,height:15)
                                        Text(LocalizedStringKey("cardList.external.disable"))
                                    } else {
                                        Circle()
                                            .fill(Color.green)
                                            .stroke(Color.gray, lineWidth: 1.5)
                                            .frame(width:15,height:15)
                                        Text(LocalizedStringKey("cardList.external.enable"))
                                    }
                                }
                            }
                            Text(LocalizedStringKey("cardList.external.description"))
                                .font(.caption)
                                .fontWeight(.regular)
                        }
                    } footer: {
                        Text(LocalizedStringKey("cardList.description"))
                    }
                }
            }
        }
        .navigationTitle(LocalizedStringKey(items.first?.area.region().name() ?? ""))
        .toolbar() {
            CardSortPicker(sort:$sort)
        }
    }
    
    func sortItems(sort: SortType, items: [CardInfo], pref: Bool) -> [CardInfo] {
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
                if pref {
                    String(prefSort($0.prefectures?.first ?? "")).localizedStandardCompare(
                        String(prefSort($1.prefectures?.first ?? ""))
                    ) == .orderedAscending
                } else {
                    Localize($0.area.sortName()).localizedStandardCompare(
                        Localize($1.area.sortName())
                    ) == .orderedAscending
                }

            case .locate_descend:
                if pref {
                    String(prefSort($0.prefectures?.first ?? "")).localizedStandardCompare(
                        String(prefSort($1.prefectures?.first ?? ""))
                    ) == .orderedDescending
                } else {
                    Localize($0.area.sortName()).localizedStandardCompare(
                        Localize($1.area.sortName())
                    ) == .orderedDescending
                }
            }
        }
    }
}
struct CardSortPicker: View {
    @Binding var sort:SortType
    var body: some View {
        Menu {
            Picker("", selection: $sort) {
                ForEach(SortType.allCases, id: \.self) { item in
                    Text(LocalizedStringKey(item.rawValue))
                }
            }
        } label: {
            Image(systemName:"arrow.up.arrow.down")
        }
    }
}

#Preview {
    CardList(deleteAds: .constant(false), smartCardManager: SmartCardManager())
}
