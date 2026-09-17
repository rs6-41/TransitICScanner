import SwiftUI

struct EnableTestCardsView: View {
    @EnvironmentObject var store: CardItemsStore

    var body: some View {
        List {
            ForEach(devCards, id: \.name) { card in
                EnableTestCard(card: card)
            }
        }
        .navigationTitle(LocalizedStringKey("setting.debug.enableTestCards"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EnableTestCard: View {
    @EnvironmentObject var store: CardItemsStore

    let card: CardInfo

    var body: some View {
        Toggle(
            isOn: Binding(
                get: {
                    store.cardItems.contains {
                        $0.name == card.name
                    }
                },
                set: { newValue in
                    if newValue {
                        if !store.cardItems.contains(where: {
                            $0.name == card.name
                        }) {
                            store.cardItems.append(card)
                        }
                    } else {
                        store.cardItems.removeAll {
                            $0.name == card.name
                        }
                    }
                }
            )
        ) {
            Text(LocalizedStringKey(card.name))
        }
    }
}

#Preview {
    EnableTestCardsView()
        .environmentObject(cardItemsStore)
}
