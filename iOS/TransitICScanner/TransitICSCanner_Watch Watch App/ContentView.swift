import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var cards: [Result] = []
    @State private var modelContainer: ModelContainer?

    var body: some View {
        NavigationStack {
            List {
                ForEach(cards, id: \.self) { card in
                    HStack {
                        Image(card.info?.iconName ?? "")
                            .resizable()
                            .scaledToFit()
                            .frame(width:35)
                        VStack(alignment:.leading) {
                            Text(card.info?.displayName ?? card.info?.name ?? "")
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            if let balance = card.balance {
                                if let currency = card.info?.currencyType?.getLocalize(String(balance)) {
                                    Text(currency)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.horizontal,5)
                    }
                }
            }
            .task {
                do {
                    let container = try SavedDataModelContainer.makeContainer()
                    modelContainer = container
                    cards = try ResultSave.loadResults(
                        from: container.mainContext
                    )
                } catch {
                    print("保存データの読み込みに失敗しました:", error)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
