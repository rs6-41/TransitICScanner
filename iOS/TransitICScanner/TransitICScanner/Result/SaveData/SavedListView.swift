import SwiftUI
import SwiftData
import TipKit

struct SavedListView: View {
    @Query
    private var cards: [SavedCard]

    @Environment(\.modelContext) private var modelContext
    @State var saveListID: UUID = UUID()
    @State private var searchText = ""
    @Binding var deleteAds: Bool

    @State private var narrow = "all"
    @State private var sort = "dateDescending"

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
        NavigationStack {
            List {
                #if !targetEnvironment(macCatalyst)
                ListAdView(deleteAds: $deleteAds)
                #endif
                
                Section {
                    if filteredCards.isEmpty {
                        ContentUnavailableView(
                            LocalizedStringKey("history.empty"),
                            systemImage: "tram.card.fill"
                        )
                    } else {
                        ForEach(filteredCards) { card in
                            NavigationLink {
                                ResultView(
                                    result: card.result(),
                                    scandata: false,
                                    saveListID: $saveListID,
                                    deleteAds: $deleteAds
                                )
                            } label: {
                                let result = card.result()
                                
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
                                        VStack(alignment:.trailing) {
                                            if let currencyType = card.currencyType {
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
                                .id(saveListID)
                            }
                        }
                        .onDelete(perform: deleteCards)
                    }
                } header: {
                    HStack {
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
                                HStack {
                                    Spacer()
                                    Text(LocalizedStringKey(item.1))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .frame(maxWidth: .infinity,alignment:.center)
                                    Spacer()
                                    Image(systemName:"chevron.up.chevron.down")
                                }
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
                            case "dateAscending":
                                "tab.history.sort.old"
                            case "nameAscending":
                                "tab.history.sort.name"
                            case "nameDescending":
                                "tab.history.sort.name.desc"
                            default:
                                "tab.history.sort.new"
                            }
                            HStack {
                                Spacer()
                                Text(LocalizedStringKey(sortKey))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity,alignment:.center)
                                Spacer()
                                Image(systemName:"chevron.up.chevron.down")
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.glass)
                    }
                    .frame(maxWidth: 350)
                }
            }
            .onChange(of: cards) {
                if narrow != "all" && !narrowItems.contains(where: { $0.0 == narrow }) {
                    narrow = "all"
                }
            }
            .navigationTitle("tab.history")
            .searchable(
                text: $searchText,
                prompt: Text(LocalizedStringKey("search"))
            )
        }
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
