import SwiftUI
import Algorithms
import WidgetKit

// 単体ウィジェット
struct ListBalanceWidgetView: View {
    var entry: ListBalanceWidgetProvider.Entry
    
    @Environment(\.widgetFamily) var widgetFamily
    @State var models:[BalanceWidgetModel] = []
    @State var maxItems = 4
    @State var itemCount = 1
    
    var body: some View {
        VStack(spacing:4) {
            HStack {
                Text(LocalizedStringKey("widget.balance.list.title"))
                    .fontWeight(.semibold)
                Spacer()
            }
            Divider()
                .overlay(Color.gray)
            if models != [] && itemCount != 0 {
                ForEach(models.indexed(), id:\.element) { index, card in
                    ZStack {
                        Spacer()
                            .frame(width:1,height:1)
                            .onAppear() {
                                if card == notSelectionModel {
                                    itemCount -= 1
                                }
                            }
                        if card != notSelectionModel {
                            VStack(spacing:4) {
                                HStack {
                                    Text(card.DisplayName ?? "unknown")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(String(card.balance ?? 0))
                                }
                                .padding(.horizontal,6)
                                Divider()
                                    .overlay(Color.gray)
                            }
                        }
                    }
                }
                if models.count(where: { $0 != notSelectionModel }) != maxItems {
                    Spacer()
                }
            } else {
                Spacer()
                Text(LocalizedStringKey("widget.balance.list.emptySelection"))
                Spacer()
            }
        }
        .onAppear() {
            setupItemCount()
        }
        .onChange(of:widgetFamily) {
            setupItemCount()
        }
    }
    func setupItemCount() {
        switch widgetFamily {
        case .systemMedium:
            maxItems = 4
        case .systemLarge:
            maxItems = 8
        case .systemExtraLarge:
            maxItems = 16
        default:
            maxItems = 4
        }
        models = Array(entry.models.prefix(maxItems))
        itemCount = models.count
    }
}
