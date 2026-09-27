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
                    .fontWeight(.black)
                Spacer()
            }
            Divider()
                .overlay(Color.gray)
            if models != [] && itemCount != 0 {
                ForEach(models.indexed(), id:\.element) { index, card in
                    if card != notSelectionModel {
                        Group {
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
                if itemCount != maxItems {
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
            maxItems = 10
        case .systemExtraLargePortrait:
            maxItems = 16
        default:
            maxItems = 4
        }
        models = Array(entry.models.prefix(maxItems))
        
        
        itemCount = models.count
        for i in models {
            if i == notSelectionModel {
                itemCount -= 1
            }
        }
    }
}
