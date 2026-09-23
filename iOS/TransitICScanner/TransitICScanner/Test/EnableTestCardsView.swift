import SwiftUI

struct EnableTestCardsView: View {
    @EnvironmentObject var store: CardItemsStore

    var body: some View {
        List {
            Section(header:Text(LocalizedStringKey("setting.debug.enableTestCards.dev"))) {
                ForEach(devCards, id: \.name) { card in
                    EnableTestCard(card: card)
                }
            }
            Section(header:Text(LocalizedStringKey("setting.debug.enableTestCards.feature"))) {
                ForEach(featureCards, id: \.name) { card in
                    EnableTestCard(card: card)
                }
            }
            Section(header:Text(LocalizedStringKey("setting.debug.enableTestCards.rel"))) {
                ForEach(relCards, id: \.name) { card in
                    EnableTestCard(card: card)
                }
            }
        }
        .navigationTitle(LocalizedStringKey("setting.debug.enableTestCards"))
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(.top, 10)
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
