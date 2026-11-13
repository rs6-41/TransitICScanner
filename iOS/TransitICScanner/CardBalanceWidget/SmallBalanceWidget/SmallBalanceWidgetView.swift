import SwiftUI

// 単体ウィジェット
struct SmallBalanceWidgetView: View {
    var entry: SmallBalanceWidgetProvider.Entry
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.model.displayName ?? "unknown")
                .bold()
            Text(String(entry.model.balance ?? 0))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
