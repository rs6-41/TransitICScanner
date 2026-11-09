import SwiftUI
import SwiftData

struct SavedListView: View {
    @State private var cards: [ScanResult] = []
    @State private var modelContainer: ModelContainer?

    @State var isFilterSheet = false
    @State var filterType: String = ""
    var body: some View {
        List {
            ForEach(cards.filter { card in filterType.isEmpty || card.converterTypeRaw == filterType }, id: \.self) {
                card in
                NavigationLink {
                    WatchResultView(card: card)
                } label: {
                    HStack {
                        Image(card.info?.iconName ?? "")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35)
                        VStack(alignment: .leading) {
                            Text(card.info?.displayName ?? card.info?.name ?? "")
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            if let balance = card.balance {
                                if let currency = card.info?.currencyType?.getLocalize(String(balance.balanceText)) {
                                    Text(currency)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.horizontal, 5)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("watch.list.filter", systemImage: "line.3.horizontal.decrease") {
                    isFilterSheet.toggle()
                }
                .tint(filterType == "" ? .clear : .blue)
            }
        }
        .sheet(isPresented: $isFilterSheet) {
            let filterItems = Array(
                Set(cards.map { $0.converterTypeRaw ?? "" })
            ).sorted()

            NavigationStack {
                List {
                    Picker("", selection: $filterType) {
                        Text(LocalizedStringKey("watch.list.filter.all"))
                            .tag("")

                        ForEach(filterItems, id: \.self) { cardType in
                            if !cardType.isEmpty {
                                Text(LocalizedStringKey(cardType + ".short"))
                                    .tag(cardType)
                            }
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                .onChange(of: filterType) {
                    isFilterSheet = false
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
                Log.debug("保存データの読み込みに失敗しました:", error)
            }
        }
    }
}

#Preview {
    SavedListView()
}
