import SwiftUI

/// 地域ごとのカード一覧の並び順
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
    /// 読取結果を表示する処理（画面遷移は呼び出し元の CardList が行う）
    let onResult: (ScanResult) -> Void

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
