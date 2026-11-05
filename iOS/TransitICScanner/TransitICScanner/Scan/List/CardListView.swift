import SwiftUI
import CoreNFC
import Combine

struct CardList: View {
    @State private var searchText = ""
    @EnvironmentObject var getCountry: GetCountry
    @EnvironmentObject var debug: DebugModel
    @EnvironmentObject var store: CardItemsStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isDuoOpen = false

    @State var currentCountryItems: [CardInfo] = []
    @State var searchItems: [CardInfo] = []
    @State private var administrativeArea: String?
    @State private var selection: regionList?
    @State private var regionPath: [regionList] = []
    @State private var selectedResult: Result?
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    @State var isDisplayScrapingForm = false
    @Binding var deleteAds: Bool
    @ObservedObject var smartCardManager: SmartCardManager

    private var showsSidebar: Bool {
        #if targetEnvironment(macCatalyst)
        true
        #else
        horizontalSizeClass == .regular
        #endif
    }

    private var usesPhoneNavigationBarPicker: Bool {
        #if targetEnvironment(macCatalyst)
        false
        #else
        isDuoOpen
        #endif
    }

    private var sidebarSelection: Binding<regionList?>? {
        showsSidebar ? nil : $selection
    }

    var body: some View {
        Group {
            if showsSidebar {
                NavigationSplitView {
                    NavigationStack(path: $regionPath) {
                        sidebar
                            .navigationDestination(for: regionList.self) { region in
                                regionCards(for: region)
                            }
                    }
                } detail: {
                    detailColumn
                        .toolbar {
                            if usesPhoneNavigationBarPicker {
                                if #available(iOS 27.0, *) {
                                    ToolbarItem(placement: .topBarPinnedTrailing) {
                                        ScanReaderPicker(manager: smartCardManager).toolbarMenu
                                    }
                                } else {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        ScanReaderPicker(manager: smartCardManager).toolbarMenu
                                    }
                                }
                            }
                        }
                }
            } else if selection == nil {
                NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
                    sidebar
                        .toolbar {
                            if !showsSidebar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    ScanReaderPicker(manager: smartCardManager)
                                }
                            }
                        }
                } detail: {
                    detailColumn
                }
            } else {
                NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
                    sidebar
                        .toolbar {
                            if !showsSidebar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    ScanReaderPicker(manager: smartCardManager)
                                }
                            }
                        }
                } content: {
                    regionContent
                } detail: {
                }
            }
        }

        .iPhoneDuoHinge(value: $isDuoOpen)
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
            if !searchText.isEmpty {
                regionPath.removeAll()
                selection = nil
                selectedResult = nil
                preferredCompactColumn = .sidebar
            }
        }
        .onChange(of: selection) {
            selectedResult = nil
            preferredCompactColumn = selection == nil ? .sidebar : .content
        }
        .onChange(of: regionPath) {
            if regionPath.isEmpty {
                selection = nil
                selectedResult = nil
            }
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        Group {
            if showsSidebar {
                sidebarList
                    .searchable(
                        text: $searchText,
                        placement: .sidebar,
                        prompt: String(localized: "cardList.search")
                    )
                    .navigationTitle(LocalizedStringKey("cardList.title"))
            } else {
                sidebarList
                    .searchable(
                        text: $searchText,
                        prompt: Text(LocalizedStringKey("cardList.search"))
                    )
                    .navigationTitle(LocalizedStringKey("cardList.title"))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(uiColor:.quaternarySystemFill))
    }

    private var sidebarList: some View {
            List(selection: sidebarSelection) {
                Group {
#if !targetEnvironment(macCatalyst)
                    ListAdView(deleteAds: $deleteAds)
#endif
                    
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
                                CardListRow(
                                    item: item,
                                    deleteAds: $deleteAds,
                                    smartCardManager: smartCardManager,
                                    onResult: showResult
                                )
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
                                
                                if !filtFirstItem.isEmpty {
                                    if showsSidebar {
                                        Button {
                                            selectedResult = nil
                                            regionPath = [list]
                                        } label: {
                                            SquareIcon(
                                                text: LocalizedStringKey(list.first.name()),
                                                systemImage: list.first.icon(),
                                                color: Color.blue
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .contentShape(Rectangle())
                                    } else {
                                        Button {
                                            selection = list
                                            selectedResult = nil
                                            preferredCompactColumn = .content
                                        } label: {
                                            SquareIcon(
                                                text: LocalizedStringKey(list.first.name()),
                                                systemImage: list.first.icon(),
                                                color: Color.blue
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .tag(list)
                                    }
                                }
                            }
                        } header: {
                            Text(LocalizedStringKey("cardList.otherLocate"))
                        } footer: {
                            Text(LocalizedStringKey("cardList.description"))
                        }
                    } else {
                        Section {
                            ForEach(searchItems, id: \.logo) { item in
                                CardListRow(
                                    item: item,
                                    deleteAds: $deleteAds,
                                    smartCardManager: smartCardManager,
                                    onResult: showResult
                                )
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
                .listRowBackground(Color(uiColor:.secondarySystemFill))
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                .zero
            }
    }

    @ViewBuilder
    private var regionContent: some View {
        if let selection {
            regionCards(for: selection)
                .scrollContentBackground(.hidden)
                .background(Color(uiColor:.quaternarySystemFill))
        }
    }

    private func regionCards(for region: regionList) -> some View {
        let regionItems = items(for: region)
        return CardRegionView(
            smartCardManager: smartCardManager,
            items: regionItems.items,
            subItems: regionItems.subItems,
            externalItems: regionItems.externalItems,
            deleteAds: $deleteAds,
            navigationTitle: region.first.name(),
            showsSortToolbar: !showsSidebar,
            onResult: showResult
        )
        .id(region)
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let resultToDisplay = selectedResult {
            ResultView(
                result: resultToDisplay,
                scandata: true,
                saveListID: .constant(UUID()),
                deleteAds: $deleteAds,
                onDone: {
                    selectedResult = nil
                    preferredCompactColumn = selection == nil ? .sidebar : .content
                },
                embedsNavigationStack: false
            )
        } else {
            switch smartCardManager.selectedSource {
            case .builtIn:
                if NFCNDEFReaderSession.readingAvailable {
                    DisplayEmptyView(isEnptyReader:false)
                } else {
                    DisplayEmptyView(isEnptyReader:true)
                }
            case .external:
                if let selectedReader = smartCardManager.readers.first(where: {
                    $0.id == smartCardManager.selectedReaderID
                }) {
                    DisplayEmptyView(isEnptyReader:false)
                } else {
                    DisplayEmptyView(isEnptyReader:true)
                }
            }
        }
    }
    
    @ViewBuilder
    private func DisplayEmptyView(isEnptyReader:Bool) -> some View {
        if isEnptyReader {
            EmptyViewSideBar(title: "cardList.reader.enptyReader", icon: "mediastick", description: "cardList.reader.enptyReader.description")
        } else {
            EmptyViewSideBar(title: "navigation.split.notselection", icon: "tram.card", description:nil)
        }
    }

    private func showResult(_ result: Result) {
        selectedResult = result
        preferredCompactColumn = .detail
    }

    private func items(for region: regionList) -> (items: [CardInfo], subItems: [CardInfo]?, externalItems: [CardInfo]?) {
        let firstRegionItems = store.cardItems.filter {
            ($0.regionOption == nil && $0.area.region() == region.first)
                || $0.regionOption == region.first
        }
        let regularItems = firstRegionItems.filter { $0.scanOption.scanType != .external }
        let externalItems = firstRegionItems.filter { $0.scanOption.scanType == .external }
        let subItems = region.second.map { second in
            store.cardItems.filter {
                $0.regionOption == nil
                    && $0.area.region() == second
                    && $0.scanOption.scanType != .external
            }
        }
        return (regularItems, subItems, externalItems)
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

struct iPhoneDuoHingeModifier: ViewModifier {
    @Binding var value: Bool

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content
                .onHingeChange { _, duo in
                    guard let hinge = duo.hinge else {
                        value = false
                        return
                    }
                    value = hinge.status == .partiallyOpen || hinge.status == .fullyOpen
                }
        } else {
            content
        }
    }
}

extension View {
    func iPhoneDuoHinge(value: Binding<Bool>) -> some View {
        self.modifier(iPhoneDuoHingeModifier(value: value))
    }
}
struct EmptyViewSideBar: View {
    var title:String
    var icon:String
    var description:String?
    
    var body: some View {
        ContentUnavailableView {
            Label {
                Text(LocalizedStringKey(title))
                    .font(.title2)
            } icon: {
                Image(systemName: icon)
                    .imageScale(.large)
            }
        } description: {
            if let description {
                Text(LocalizedStringKey(description))
                    .font(.body)
            }
        }
    }
}


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

    @Binding var deleteAds: Bool
    var navigationTitle: String
    var showsSortToolbar = true
    var onResult: ((Result) -> Void)? = nil

    @State var sort: SortType = .locate_ascend
    @State var sort2: SortType = .locate_ascend
    @State var sort3: SortType = .locate_ascend

    var body: some View {
        List {
            Group {
#if !targetEnvironment(macCatalyst)
                ListAdView(deleteAds: $deleteAds)
#endif
                
                Section {
                    ForEach(
                        sortItems(sort: sort, items: items, pref: false),
                        id: \.logo
                    ) { item in
                        CardListRow(
                            item: item,
                            deleteAds: $deleteAds,
                            smartCardManager: smartCardManager,
                            onResult: onResult
                        )
                    }
                } footer: {
                    Text(LocalizedStringKey("cardList.description"))
                }
                
                if let subItems {
                    if !subItems.isEmpty {
                        Section {
                            ForEach(
                                sortItems(sort: sort2, items: subItems, pref: true),
                                id: \.logo
                            ) { item in
                                CardListRow(
                                    item: item,
                                    deleteAds: $deleteAds,
                                    smartCardManager: smartCardManager,
                                    onResult: onResult
                                )
                            }
                        } header: {
                            HStack {
                                Text(
                                    LocalizedStringKey(
                                        subItems.first?.area.region().name() ?? ""
                                    )
                                )
                                Spacer()
                            }
                        } footer: {
                            Text(LocalizedStringKey("cardList.description"))
                        }
                    }
                }
                
                if let externalItems {
                    if !externalItems.isEmpty {
                        Section {
                            ForEach(
                                sortItems(
                                    sort: sort2,
                                    items: externalItems,
                                    pref: true
                                ),
                                id: \.logo
                            ) { item in
                                CardListRow(
                                    item: item,
                                    deleteAds: $deleteAds,
                                    smartCardManager: smartCardManager,
                                    externalDevice: !smartCardManager.readers.isEmpty,
                                    onResult: onResult
                                )
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(LocalizedStringKey("cardList.external.title"))
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        if smartCardManager.readers.isEmpty {
                                            Circle()
                                                .fill(Color.red)
                                                .stroke(Color.gray, lineWidth: 1.5)
                                                .frame(width: 15, height: 15)
                                            
                                            Text(LocalizedStringKey("cardList.external.disable"))
                                        } else {
                                            Circle()
                                                .fill(Color.green)
                                                .stroke(Color.gray, lineWidth: 1.5)
                                                .frame(width: 15, height: 15)
                                            
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
            .listRowBackground(Color(uiColor:.secondarySystemFill))
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .navigationTitle(
            LocalizedStringKey(navigationTitle)
        )
        .toolbar {
            if showsSortToolbar {
                CardSortPicker(sort: $sort)
            }
        }
    }

    func sortItems(
        sort: SortType,
        items: [CardInfo],
        pref: Bool
    ) -> [CardInfo] {
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
                    String(prefSort($0.prefectures?.first ?? ""))
                        .localizedStandardCompare(
                            String(prefSort($1.prefectures?.first ?? ""))
                        ) == .orderedAscending
                } else {
                    Localize($0.area.sortName()).localizedStandardCompare(
                        Localize($1.area.sortName())
                    ) == .orderedAscending
                }

            case .locate_descend:
                if pref {
                    String(prefSort($0.prefectures?.first ?? ""))
                        .localizedStandardCompare(
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
    @Binding var sort: SortType

    var body: some View {
        Menu {
            Picker("", selection: $sort) {
                ForEach(SortType.allCases, id: \.self) { item in
                    Text(LocalizedStringKey(item.rawValue))
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}

#Preview {
    CardList(
        deleteAds: .constant(false),
        smartCardManager: SmartCardManager()
    )
}
