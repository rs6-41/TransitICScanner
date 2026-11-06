import SwiftUI

struct WatchResultView: View {
    var card: Result
    var body: some View {
        List {
            Section() {
                HStack {
                    Image(card.info?.iconName ?? "")
                        .resizable()
                        .scaledToFit()
                        .frame(width:35)
                    Text(card.info?.displayName ?? "")
                        .fontWeight(.semibold)
                }
                
                if let balance = card.balance {
                    if let currency = card.info?.currencyType?.getLocalize(String(balance.balanceText)) {
                        LabeledContent(LocalizedStringKey("result.history.balance")) {
                            Text(currency)
                        }
                    }
                }
            }
            Section() {
                if let cardCategory = card.info?.name, cardCategory != "" {
                    LabeledContent(LocalizedStringKey("result.info.cardCategory")) {
                        Text(LocalizedStringKey(cardCategory))
                    }
                }
                
                if let cardType = card.info?.type, Localize(card.info?.name ?? "") != Localize(cardType) && cardType != "" {
                    LabeledContent(LocalizedStringKey("result.info.cardType")) {
                        if card.info?.name ?? "" == "cnTunion" {
                            Text(String(localized: String.LocalizationValue(cardType), table: "cnTunion_cards"))
                        } else {
                            Text(LocalizedStringKey(cardType))
                        }
                    }
                }
            } header: {
                Text(LocalizedStringKey("result.info"))
            }
        }
    }
}
