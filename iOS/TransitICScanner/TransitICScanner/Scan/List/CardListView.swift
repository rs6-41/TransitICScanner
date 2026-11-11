import SwiftUI
import CoreNFC
import Combine

/// スキャンタブ：カード一覧から読み取りを始め、結果画面へ遷移する
///
/// 画面幅によって遷移の仕組みを切り替える。
/// - iPad・Mac・開いた iPhone Duo（regular 幅）：`NavigationSplitView`。
///   左に地域・カード一覧、右（詳細列）に読取結果を表示する
/// - iPhone（compact 幅）：`NavigationStack` のパス(`compactPath`)に積んでプッシュ遷移する。
///   一覧 → 地域 → 結果 の順に積むため、どの階層から読み取っても結果画面へアニメーション付きで遷移する
struct CardList: View {
    /// iPhone（compact 幅）での遷移先
    enum CompactRoute: Hashable {
        case region(RegionList)
        case result(ScanResult)
    }

    @EnvironmentObject var getCountry: GetCountry
    @EnvironmentObject var debug: DebugModel
    @EnvironmentObject var store: CardItemsStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var deleteAds: Bool
    @ObservedObject var smartCardManager: SmartCardManager

    // 一覧の内容
    @State private var searchText = ""
    @State private var currentCountryItems: [CardInfo] = []
    @State private var searchItems: [CardInfo] = []
    @State private var administrativeArea: String?

    // 画面遷移（regular 幅）
    @State private var regionPath: [RegionList] = []
    @State private var selectedResult: ScanResult?

    // 画面遷移（compact 幅）
    @State private var compactPath: [CompactRoute] = []

    @State private var isDuoOpen = false

    /// 分割表示（サイドバー＋詳細列）を使うか
    private var showsSidebar: Bool {
        #if targetEnvironment(macCatalyst)
        true
        #else
        horizontalSizeClass == .regular
        #endif
    }

    /// 開いた iPhone Duo では、読取方式の切り替えをナビゲーションバーに置く
    private var usesPhoneNavigationBarPicker: Bool {
        #if targetEnvironment(macCatalyst)
        false
        #else
        isDuoOpen
        #endif
    }

    var body: some View {
        Group {
            if showsSidebar {
                splitView
            } else {
                compactStack
            }
        }
        .iPhoneDuoHinge(value: $isDuoOpen)
        .onAppear {
            getCountry.start()
            refreshCurrentLocation()
        }
        .onChange(of: getCountry.countryCode) {
            refreshCurrentLocation()
        }
        .onChange(of: searchText) {
            search()
            if !searchText.isEmpty {
                regionPath.removeAll()
                selectedResult = nil
            }
        }
        .onChange(of: regionPath) {
            if regionPath.isEmpty {
                selectedResult = nil
            }
        }
    }

    // MARK: - 画面遷移

    /// iPad・Mac：サイドバーに一覧、詳細列に読取結果
    private var splitView: some View {
        NavigationSplitView {
            NavigationStack(path: $regionPath) {
                sidebar
                    .navigationDestination(for: RegionList.self) { region in
                        regionCards(for: region)
                    }
            }
        } detail: {
            detailColumn
                .toolbar {
                    if usesPhoneNavigationBarPicker {
                        readerPickerToolbarItem
                    }
                }
        }
    }

    /// iPhone：一覧 → 地域 → 結果 をプッシュ遷移
    private var compactStack: some View {
        NavigationStack(path: $compactPath) {
            sidebar
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ScanReaderPicker(manager: smartCardManager)
                    }
                }
                .navigationDestination(for: CompactRoute.self) { route in
                    switch route {
                    case .region(let region):
                        regionCards(for: region)
                            .scrollContentBackground(.hidden)
                            .background(Color(uiColor: .quaternarySystemFill))
                    case .result(let result):
                        resultView(result) {
                            if !compactPath.isEmpty {
                                compactPath.removeLast()
                            }
                        }
                    }
                }
        }
    }

    @ToolbarContentBuilder
    private var readerPickerToolbarItem: some ToolbarContent {
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

    /// 地域を開く
    private func openRegion(_ region: RegionList) {
        if showsSidebar {
            selectedResult = nil
            regionPath = [region]
        } else {
            compactPath.append(.region(region))
        }
    }

    /// 読取結果を表示する（各カードの行から呼ばれる）
    private func showResult(_ result: ScanResult) {
        if showsSidebar {
            selectedResult = result
        } else {
            compactPath.append(.result(result))
        }
    }

    // MARK: - 一覧

    private var sidebar: some View {
        List {
            Group {
#if !targetEnvironment(macCatalyst)
                ListAdView(deleteAds: $deleteAds)
#endif
                
                if debug.isDisplay {
                    debugLocationRow
                }
                
                if !currentCountryItems.isEmpty {
                    currentLocationSection
                }
                
                if searchText.isEmpty {
                    regionSection
                } else {
                    searchResultSection
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemFill))
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .alignmentGuide(.listRowSeparatorLeading) { _ in
                .zero
        }
        .searchable(
            text: $searchText,
            placement: showsSidebar ? .sidebar : .automatic,
            prompt: Text(LocalizedStringKey("cardList.search"))
        )
        .navigationTitle(LocalizedStringKey("cardList.title"))
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .quaternarySystemFill))
    }

    /// 現在地で使えるカード
    private var currentLocationSection: some View {
        Section {
            ForEach(currentCountryItems, id: \.logo) { item in
                cardRow(item)
            }
        } header: {
            Text(LocalizedStringKey("cardList.nowLocate"))
        }
    }

    /// 他の地域（地域を選ぶと、その地域のカード一覧へ遷移する）
    private var regionSection: some View {
        Section {
            ForEach(regionLists, id: \.self) { region in
                if !cards(inPrimaryRegionOf: region).isEmpty {
                    Button {
                        openRegion(region)
                    } label: {
                        SquareIcon(
                            text: LocalizedStringKey(region.first.name()),
                            systemImage: region.first.icon(),
                            color: Color.blue
                        )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
        } header: {
            Text(LocalizedStringKey("cardList.otherLocate"))
        } footer: {
            Text(LocalizedStringKey("cardList.description"))
        }
    }

    /// 検索結果
    private var searchResultSection: some View {
        Section {
            ForEach(searchItems, id: \.logo) { item in
                cardRow(item)
            }
        } header: {
            Text(LocalizedStringKey("cardList.searchResults"))
        } footer: {
            Text(LocalizedStringKey("cardList.description"))
        }
    }

    /// （デバッグ表示）現在地の判定結果
    private var debugLocationRow: some View {
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

    private func cardRow(_ item: CardInfo) -> some View {
        CardListRow(
            item: item,
            smartCardManager: smartCardManager,
            onResult: showResult
        )
    }

    private func regionCards(for region: RegionList) -> some View {
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

    // MARK: - 結果

    private func resultView(_ result: ScanResult, onDone: @escaping () -> Void) -> some View {
        ResultView(
            result: result,
            scandata: true,
            saveListID: .constant(UUID()),
            deleteAds: $deleteAds,
            onDone: onDone,
            showsSidebar: showsSidebar
        )
    }

    /// iPad・Mac の詳細列：読取結果、または未選択時の案内
    @ViewBuilder
    private var detailColumn: some View {
        if let selectedResult {
            resultView(selectedResult) {
                self.selectedResult = nil
            }
        } else if isReaderAvailable {
            EmptyViewSideBar(
                title: "navigation.split.notselection",
                icon: "tram.card",
                description: nil
            )
        } else {
            EmptyViewSideBar(
                title: "cardList.reader.enptyReader",
                icon: "mediastick",
                description: "cardList.reader.enptyReader.description"
            )
        }
    }

    /// 選択中の読取方式で読み取りができるか
    private var isReaderAvailable: Bool {
        switch smartCardManager.selectedSource {
        case .builtIn:
            NFCNDEFReaderSession.readingAvailable
        case .external:
            smartCardManager.readers.contains {
                $0.id == smartCardManager.selectedReaderID
            }
        }
    }

    // MARK: - 一覧の内容

    /// 地域の第1区分に含まれるカード
    private func cards(inPrimaryRegionOf region: RegionList) -> [CardInfo] {
        store.cardItems.filter {
            ($0.regionOption == nil && $0.area.region() == region.first)
                || $0.regionOption == region.first
        }
    }

    private func items(for region: RegionList) -> (items: [CardInfo], subItems: [CardInfo]?, externalItems: [CardInfo]?)
    {
        let primaryItems = cards(inPrimaryRegionOf: region)
        let regularItems = primaryItems.filter { $0.scanOption.scanType != .external }
        let externalItems = primaryItems.filter { $0.scanOption.scanType == .external }
        let subItems = region.second.map { second in
            store.cardItems.filter {
                $0.regionOption == nil
                    && $0.area.region() == second
                    && $0.scanOption.scanType != .external
            }
        }
        return (regularItems, subItems, externalItems)
    }

    /// 現在地（国・都道府県）を取り直して、現在地のカード一覧を更新する
    private func refreshCurrentLocation() {
        updateCurrentCountryItems()

        Task {
            administrativeArea = await getCountry.fetchAdministrativeArea()
            updateCurrentCountryItems()
        }
    }

    private func updateCurrentCountryItems() {
        currentCountryItems = store.cardItems.filter(isAvailableAtCurrentLocation)
    }

    private func isAvailableAtCurrentLocation(_ item: CardInfo) -> Bool {
        guard let currentCode = getCountry.countryCode,
            item.countryCode.contains(currentCode)
        else {
            return false
        }

        // 都道府県の指定がないカードは国全体で使える
        guard let prefectures = item.prefectures else {
            return true
        }

        guard let administrativeArea else {
            return false
        }

        return prefectures.contains(administrativeArea)
    }

    private func search() {
        guard !searchText.isEmpty else {
            updateCurrentCountryItems()
            return
        }

        currentCountryItems = []
        searchItems = store.cardItems.filter { item in
            item.matchesSearch(searchText)
                || Localize(item.area.rawValue).localizedCaseInsensitiveContains(searchText)
        }
    }
}

#Preview {
    CardList(
        deleteAds: .constant(false),
        smartCardManager: SmartCardManager()
    )
}
