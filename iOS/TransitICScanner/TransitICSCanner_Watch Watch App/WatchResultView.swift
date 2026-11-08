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
                if let savedAt = card.savedAt {
                    LabeledContent {
                        Text(String(savedAt.formatted(date: .numeric, time: .shortened)))
                    } label: {
                        Image(systemName:"clock.arrow.trianglehead.2.counterclockwise.rotate.90")
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
            Section {
                if card.isHistory {
                    if let history = card.history {
                        let sortedHistory = history.sorted {
                            $0.transactionId > $1.transactionId
                        }

                        ForEach(
                            Array(sortedHistory.enumerated()),
                            id: \.element
                        ) { index, item in
                            resultHistoryRow(
                                index: index,
                                item: item,
                                history: sortedHistory
                            )
                        }
                    } else {
                        Text(
                            LocalizedStringKey("result.history.empty")
                        )
                        .foregroundStyle(Color.gray)
                    }
                } else {
                    Text(
                        LocalizedStringKey("result.history.notHistory")
                    )
                    .foregroundStyle(Color.gray)
                }
            } header: {
                Text(LocalizedStringKey("result.history.balance"))
            }
        }
    }
    
    @ViewBuilder
    private func resultHistoryRow(
        index: Int,
        item: ResultHistory,
        history: [ResultHistory]
    ) -> some View {
        let hasNext = index + 1 < history.count
        let nextBalance: Double =
            hasNext
                ? history[index + 1].balance
                : 0

        let diff: Double? =
            hasNext
                ? item.balance - nextBalance
                : (card.isLastHide ? nil : item.balance)

        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            HStack {
                ZStack {
                    if item.date.month != 0 && item.date.day != 0 {
                        if let date = Calendar.current.date(from: item.date) {
                            if item.date.year != 0 {
                                Text(date, format: .dateTime.year().month().day())
                            } else {
                                Text(date, format: .dateTime.month().day())
                            }
                        }
                    }
                }
                .foregroundStyle(Color.gray)
            }

            HStack(spacing: 2) {
                let balanceText =
                String(item.balance.balanceText)
                let currency = card.info?.currencyType?.getLocalize(balanceText)
                Text(currency ?? LocalizedStringKey(balanceText))
                
                Spacer()
                
                if let diff {
                    let amount = resultHistoryAmount(diff: diff)
                    let currency = card.info?.currencyType?.getLocalize(amount)
                    Group {
                        if let currency {
                            Text("(\(Text(currency)))")
                        } else {
                            Text("(\(amount))")
                        }
                    }
                    .foregroundStyle(
                        diff >= 0 ? .green : .red
                    )
                }
            }
        }
    }

    private func resultHistoryAmount(diff: Double) -> String {
        if diff == 0 {
            return "0"
        } else {
            let sign = diff >= 0 ? "+" : "-"
            let amount = abs(diff).balanceText
            return String("\(sign)\(amount)")
        }
    }
}
