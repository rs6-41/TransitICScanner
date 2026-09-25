import SwiftUI

// 単体ウィジェット
struct SmallBalanceWidgetView: View {
    var entry: SmallBalanceWidgetProvider.Entry
    var body: some View {
        if let card = entry.models.first {
            VStack(alignment:.leading) {
                Text(card.DisplayName ?? "unknown")
                    .bold()
                Text(String(card.balance ?? 0))
                Spacer()
            }
            .frame(maxWidth:.infinity)
        }
    }
}
