import SwiftUI
import SwiftData
import TipKit

struct SavedListView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query
    private var cards: [SavedCard]

    @Environment(\.modelContext) private var modelContext
    @State var saveListID: UUID = UUID()
    @State private var searchText = ""
    @Binding var deleteAds: Bool

    @State private var narrow = "all"
    @State private var sort = "dateDescending"
    @State private var selectedCardID: PersistentIdentifier?
    @State private var selectedResult: ScanResult?
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    private var showsSidebar: Bool {
        #if targetEnvironment(macCatalyst)
        true
        #else
        horizontalSizeClass == .regular
        #endif
    }

    private var sidebarSelection: Binding<PersistentIdentifier?>? {
        showsSidebar ? nil : $selectedCardID
    }

    private var filteredCards: [SavedCard] {
        var result = cards

        if narrow != "all" {
            result = result.filter { card in
                card.name == narrow
            }
        }

        if !searchText.isEmpty {
            result = result.filter { card in
                let cardResult = card.result()

                let name = card.name
                let nameShort = card.nameShort
                let displayName = cardResult.info?.displayName ?? ""
                let type = cardResult.info.map {
                    cardResult.converter.cardInfo($0).type
                } ?? ""

                return name.localizedCaseInsensitiveContains(searchText)
                    || nameShort.localizedCaseInsensitiveContains(searchText)
                    || displayName.localizedCaseInsensitiveContains(searchText)
                    || type.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sort {
        case "dateAscending":
            result.sort {
                $0.savedAt ?? Date.now < $1.savedAt ?? Date.now
            }

        case "nameAscending":
            result.sort {
                $0.name.localizedCompare($1.name) == .orderedAscending
            }

        case "nameDescending":
            result.sort {
                $0.name.localizedCompare($1.name) == .orderedDescending
            }

        default:
            result.sort {
                $0.savedAt ?? Date.now > $1.savedAt ?? Date.now
            }
        }

        return result
    }

    private var narrowItems: [(String, String)] {
        var items: [(String, String)] = [
            ("all", String(localized:"tab.history.narrow.all"))
        ]

        let cardTypes = Dictionary(
            grouping: cards,
            by: { $0.name }
        )

        for (name, cards) in cardTypes {
            guard let card = cards.first else {
                continue
            }

            let result = card.result()

            let nameShort: String

            if let info = result.info {
                nameShort = info.nameShort
            } else {
                nameShort = name
            }

            items.append((name, nameShort))
        }

        return items.sorted { lhs, rhs in
            if lhs.0 == "all" {
                return true
            }

            if rhs.0 == "all" {
                return false
            }

            return lhs.1.localizedCompare(rhs.1) == .orderedAscending
        }
    }

    var body: some View {
        Group {
            if showsSidebar {
                NavigationSplitView {
                    NavigationStack {
                        savedCardList
                    }
                } detail: {
                    detailColumn
                }
            } else {
                NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
                    savedCardList
                } detail: {
                    detailColumn
                }
            }
        }
    }

    private var savedCardList: some View {
        List(selection: sidebarSelection) {
            Group {
#if !targetEnvironment(macCatalyst)
                ListAdView(deleteAds: $deleteAds)
#endif
                Section {
                    HStack(spacing: 8) {
                        Menu {
                            Picker(
                                "tab.history.narrow",
                                selection: $narrow
                            ) {
                                ForEach(narrowItems, id: \.0) { item in
                                    Text(LocalizedStringKey(item.1))
                                        .tag(item.0)
                                }
                            }
                        } label: {
                            if let item = narrowItems.first(where: { $0.0 == narrow }) {
                                pickerLabel(item.1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.glass)
                        
                        Menu {
                            Picker(
                                "tab.history.sort",
                                selection: $sort
                            ) {
                                Text(LocalizedStringKey("tab.history.sort.new"))
                                    .tag("dateDescending")
                                Text(LocalizedStringKey("tab.history.sort.old"))
                                    .tag("dateAscending")
                                Text(LocalizedStringKey("tab.history.sort.name"))
                                    .tag("nameAscending")
                                Text(LocalizedStringKey("tab.history.sort.name.desc"))
                                    .tag("nameDescending")
                            }
                        } label: {
                            let sortKey: String = switch sort {
                            case "dateAscending": "tab.history.sort.old"
                            case "nameAscending": "tab.history.sort.name"
                            case "nameDescending": "tab.history.sort.name.desc"
                            default: "tab.history.sort.new"
                            }
                            pickerLabel(sortKey)
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.glass)
                    }
                    .listRowInsets(EdgeInsets(
                        top: 8,
                        leading: horizontalSizeClass == .regular ? 0 : 16,
                        bottom: 8,
                        trailing: horizontalSizeClass == .regular ? 0 : 16
                    ))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                Section {

                    if filteredCards.isEmpty {
                        ContentUnavailableView(
                            LocalizedStringKey("history.empty"),
                            systemImage: "tram.card.fill"
                        )
                    } else {
                        ForEach(filteredCards) { card in
                            let result = card.result()

                            Button {
                                selectedCardID = card.persistentModelID
                                selectedResult = card.result()
                                preferredCompactColumn = .detail
                            } label: {
                                HStack {
                                    let iconName = result.info?.iconName

                                    if iconName != "" {
                                        CardImage(name: iconName ?? "")
                                    } else if let info = result.info {
                                        let display = result.converter.cardInfo(info)

                                        if let cardName = getCardImageName(
                                            type: card.converterType,
                                            name: display.type
                                        ) {
                                            CardImage(name: cardName.imageName)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        if result.info?.displayName ?? "" != "" {
                                            Text(
                                                LocalizedStringKey(
                                                    result.info?.displayName ?? ""
                                                )
                                            )
                                            .font(.headline)

                                            Text(LocalizedStringKey(card.name))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)

                                        } else if let info = result.info,
                                                  !result.converter.cardInfo(info).type.isEmpty {
                                            Text(
                                                LocalizedStringKey(
                                                    result.converter.cardInfo(info).type
                                                )
                                            )
                                            .font(.headline)

                                            Text(LocalizedStringKey(card.name))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)

                                        } else {
                                            Text(LocalizedStringKey(card.nameShort))
                                                .font(.headline)
                                        }
                                    }

                                    Spacer()

                                    if let balance = card.balance {
                                        VStack(alignment: .trailing) {
                                            if let currencyType = card.parsedCurrencyType {
                                                Text(currencyType.getLocalize(balance.balanceText))
                                            }
                                            if let savedAt = card.savedAt {
                                                Text(savedAt, format: Date.FormatStyle(date: .numeric, time: .omitted))
                                                    .font(.caption)
                                                    .foregroundStyle(Color.gray)
                                            }
                                        }
                                    }
                                }
#if targetEnvironment(macCatalyst)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
#endif
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .tag(card.persistentModelID)
                        }
                        .onDelete(perform: deleteCards)
                    }
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemFill))
            .listSectionSpacing(.compact)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .onChange(of: cards) {
            if narrow != "all" && !narrowItems.contains(where: { $0.0 == narrow }) {
                narrow = "all"
            }
            if let selectedCardID,
               !cards.contains(where: { $0.persistentModelID == selectedCardID }) {
                self.selectedCardID = nil
                selectedResult = nil
                preferredCompactColumn = .sidebar
            }
        }
        .navigationTitle("tab.history")
        .searchable(
            text: $searchText,
            prompt: Text(LocalizedStringKey("search"))
        )
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let selectedResult {
            ResultView(
                result: selectedResult,
                scandata: false,
                saveListID: $saveListID,
                deleteAds: $deleteAds,
                embedsNavigationStack: false
            )
            .id(selectedCardID)
        } else {
            EmptyViewSideBar(
                title: "history.select.empty",
                icon: "filemenu.and.pointer.arrow",
                description: "history.select.empty.description"
            )
        }
    }

    private func pickerLabel(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(LocalizedStringKey(title))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .center)
            Image(systemName: "chevron.up.chevron.down")
        }
        .padding(.horizontal, 8)
    }

    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredCards[index])
        }

        do {
            try modelContext.save()
        } catch {
            print("保存データの削除に失敗しました: \(error)")
        }
    }
}
