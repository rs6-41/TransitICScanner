import SwiftUI
import SwiftData


struct SavedListView: View {
    @Query(sort: \SavedCard.name)
    private var cards: [SavedCard]

    @Environment(\.modelContext) private var modelContext
    @State var saveListID:UUID = UUID() //Viewの強制更新
    @Binding var deleteAds:Bool

    var body: some View {
        NavigationStack {
            List {
                ListAdView(deleteAds:$deleteAds)
                
                ForEach(cards) { card in
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
                                CardImage(name:iconName ?? "")
                            } else if let info = result.info {
                                let display = result.converter.cardInfo(info)
                                if let cardName = getCardImageName(type: card.converterType, name: display.type) {
                                    CardImage(name:cardName.imageName)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                if result.info?.displayName ?? "" != "" {
                                    Text(LocalizedStringKey(result.info?.displayName ?? ""))
                                        .font(.headline)
                                    Text(LocalizedStringKey(card.name))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else if let info = result.info,!result.converter.cardInfo(info).type.isEmpty {
                                    Text(LocalizedStringKey(result.converter.cardInfo(info).type))
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
                                HStack(spacing:2) {
                                    Text(LocalizedStringKey(balance.balanceText))
                                    Text(LocalizedStringKey(card.currency))
                                }
                            }
                        }
                        
                        .id(saveListID)
                    }
                }
                .onDelete(perform: deleteCards)
            }
            .navigationTitle("tab.history")
            .onAppear() {
                print("保存件数:\(cards.count)")
            }
        }
    }

    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(cards[index])
        }

        do {
            try modelContext.save()
        } catch {
            print("保存データの削除に失敗しました: \(error)")
        }
    }
}
