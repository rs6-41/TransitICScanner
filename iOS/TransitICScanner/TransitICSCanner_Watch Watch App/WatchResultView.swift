import SwiftUI

struct WatchResultView: View {
    var card: Result
    var body: some View {
        List {
            if let balance = card.balance {
                if let currency = card.info?.currencyType?.getLocalize(String(balance.balanceText)) {
                    LabeledContent(LocalizedStringKey("result.history.balance")) {
                        Text(currency)
                    }
                }
            }
        }
    }
}
