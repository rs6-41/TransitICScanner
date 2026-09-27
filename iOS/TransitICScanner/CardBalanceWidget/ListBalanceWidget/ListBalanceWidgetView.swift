import SwiftUI
import Algorithms
import WidgetKit

struct ListBalanceWidgetView: View {
    var entry: ListBalanceWidgetProvider.Entry
    
    @Environment(\.widgetFamily) var widgetFamily
    
    var maxItems: Int {
        switch widgetFamily {
        case .systemSmall:
            return 4
        case .systemMedium:
            return 4
        case .systemLarge:
            return 12
        case .systemExtraLargePortrait:
            return 19
        default:
            return 4
        }
    }
    
    var models: [BalanceWidgetModel] {
        let result = Array(
            entry.models
                .filter { $0 != notSelectionModel }
                .prefix(maxItems)
        )
        
        print("View: entry.models = \(entry.models.count)")
        print("View: filtered models = \(result.count)")
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment:.top) {
                HStack(spacing:5) {
                    Image(systemName:"tram.fill")
                    Text(LocalizedStringKey("widget.balance.list.title"))
                        .fontWeight(.black)
                    Spacer()
                    HStack(spacing:2) {
                        Image(systemName:"clock.arrow.trianglehead.counterclockwise.rotate.90")
                        Text(entry.updateDate, format: Date.FormatStyle(date: .numeric, time: .shortened))
                    }
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
            }
            
            Divider()
                .overlay(Color.gray)
            
            if models.isEmpty {
                Spacer()
                HStack(spacing:5) {
                    Image(systemName:"widget.large.badge.plus")
                        .imageScale(.small)
                    Text(LocalizedStringKey("widget.balance.list.emptySelection"))
                }
                Spacer()
            } else {
                ForEach(models, id: \.idm) { card in
                    VStack(spacing: 2) {
                        HStack {
                            
                            if let iconName = card.icon {
                                Image(iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 16)
                            }
                            Text(card.DisplayName ?? "unknown")
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            HStack(spacing: 0) {
                                let balance = String(card.balance?.balanceText ?? String(localized: "unknown"))
                                if let currencyType = card.currencyType {
                                    Text(currencyType.getLocalize(balance))
                                } else {
                                    Text(balance)
                                }
                            }
                        }
                        .padding(.horizontal, 6)
                        
                        .lineLimit(1)
                        
                        Divider()
                            .overlay(Color.gray)
                    }
                }
                
                if models.count < maxItems {
                    Spacer()
                }
            }
        }
    }
}
