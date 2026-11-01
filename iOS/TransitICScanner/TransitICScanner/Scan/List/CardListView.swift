import SwiftUI
import CoreNFC
import Combine

struct CardList: View {
    @State private var searchText = ""
    @EnvironmentObject var getCountry: GetCountry
    @EnvironmentObject var debug: DebugModel
    @EnvironmentObject var store: CardItemsStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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

    @State private var scrollOffsetY: CGFloat = 0
    @State private var searchBarOffsetY: CGFloat = 0
    @State var searchBarHight: CGFloat = 0
    @State var isSearchFocused: Bool = false
    @State private var searchBarIsBelowToolbar = true

    // Toolbar layout reserves less space than the visible gap at the trailing
    // edge, so include the additional list inset in the expansion width.
    private let trailingToolbarWidth: CGFloat = 60

    private var showsSidebar: Bool {
        #if targetEnvironment(macCatalyst)
        true
        #else
        horizontalSizeClass == .regular
        #endif
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
                }
            } else if selection == nil {
                NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
                    sidebar
                } detail: {
                    detailColumn
                        .toolbar {
                            if !showsSidebar {
                                ToolbarItem(placement: .navigation) {
                                    ScanReaderPicker(manager: smartCardManager)
                                }
                            }
                        }
                }
            } else {
                NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
                    sidebar
                } content: {
                    regionContent
                } detail: {
                    detailColumn
                        .toolbar {
                            if !showsSidebar {
                                ToolbarItem(placement: .navigation) {
                                    ScanReaderPicker(manager: smartCardManager)
                                }
                            }
                        }
                }
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
                .navigationTitle(LocalizedStringKey("cardList.title"))
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar {
                    ToolbarItem(placement: .title) {
                        Text("")
                    }

                    ToolbarItem(placement: .subtitle) {
                        HStack {
                            SearchBar(
                                text: $searchText,
                                isFocused: $isSearchFocused,
                                placeholder: String(localized: "cardList.search")
                            )

                            #if !targetEnvironment(macCatalyst)
                            Button {
                                withAnimation(.linear(duration: 0.3)) {
                                    isSearchFocused = false
                                    searchText = ""
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            .opacity(isSearchFocused ? 1 : 0)
                            .frame(width: isSearchFocused ? 40 : 0)
                            #endif
                        }
                        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
                        .animation(.easeInOut(duration: 0.18), value: searchBarIsBelowToolbar)
                        .padding(
                            .trailing,
                            searchBarIsBelowToolbar ? -trailingToolbarWidth : 0
                        )
                        .offset(y: max(0, searchBarOffsetY))
                        .zIndex(1)
                        .onGeometryChange(
                            for: CGFloat.self,
                            of: { $0.size.height },
                            action: { searchBarHight = $0 }
                        )
                    }
                }
        }
    }

    private var sidebarList: some View {
            List(selection: $selection) {
                if !showsSidebar {
                Section {
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
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                .listRowInsets(
                    EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                )
                .listRowBackground(Color.clear)
                }

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
                                Button {
                                    selection = list
                                    selectedResult = nil
                                    if showsSidebar {
                                        regionPath = [list]
                                    } else {
                                        preferredCompactColumn = .content
                                    }
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
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                .zero
            }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { oldVal, newVal in
            scrollOffsetY = newVal

            let nextOffset: CGFloat
            if scrollOffsetY < searchBarHight {
                nextOffset = -(scrollOffsetY + searchBarHight)
            } else {
                nextOffset = -scrollOffsetY
            }

            searchBarOffsetY = nextOffset

            // Keep the expanded width while the bar is visually below the
            // toolbar button. A small dead band prevents flicker at the edge.
            if nextOffset < -2, searchBarIsBelowToolbar {
                searchBarIsBelowToolbar = false
            } else if nextOffset > 2, !searchBarIsBelowToolbar {
                searchBarIsBelowToolbar = true
            }
        }
    }

    @ViewBuilder
    private var regionContent: some View {
        if let selection {
            regionCards(for: selection)
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
            Text("navigation.split.notselection")
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
