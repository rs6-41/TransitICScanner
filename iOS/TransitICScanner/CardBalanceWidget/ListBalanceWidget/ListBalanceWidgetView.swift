import SwiftUI

// 単体ウィジェット
struct ListBalanceWidgetView: View {
    var entry: ListBalanceWidgetProvider.Entry
    
    var body: some View {
        ForEach(entry.models, id:\.idm) { card in
            HStack {
                VStack {
                    Text(card.DisplayName ?? "unknown")
                        .bold()
                }
                Spacer()
                Text(String(card.balance ?? 0))
            }
        }
    }
}
