import SwiftUI
import Algorithms
import WidgetKit

// 単体ウィジェット
struct ListBalanceWidgetView: View {
    var entry: ListBalanceWidgetProvider.Entry
    
    @Environment(\.widgetFamily) var widgetFamily
    @State var models:[BalanceWidgetModel] = []
    @State var maxItems = 4
    
    var body: some View {
        if entry.models != [] {
            VStack(spacing:4) {
                HStack {
                    Text(LocalizedStringKey("widget.balance.list.title"))
                        .fontWeight(.semibold)
                    Spacer()
                }
                Divider()
                    .overlay(Color.gray)
                ForEach(models.indexed(), id:\.element) { index, card in
                    
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
                Spacer()
            }
            .onAppear() {
                setupItemCount()
            }
            .onChange(of:widgetFamily) {
                setupItemCount()
            }
        } else {
            Text(LocalizedStringKey("widget.balance.list.emptySelection"))
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
    }
}
