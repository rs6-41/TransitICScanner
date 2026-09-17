import SwiftUI
import SwiftData

struct ResultView: View {
    @State var result: Result
    @State var scandata: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State var cardUserName = ""
    @State var cardDesign:CardDesigin? = nil
    
    @Binding var saveListID:UUID

    var body: some View {
        NavigationStack {
            List {
                resultUserdataSection
                resultInfoSection
                resultHistorySection
            }
            .toolbar {
                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    if scandata {
                        Button(action: {
                            saveAction()
                            //複数階層でも戻るように
                            UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
                        }) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.white)
                        }
                        .tint(Color.accentColor)
                        .buttonStyle(.glassProminent)
                    }
                }
            }
            .navigationTitle(
                Text(String(localized: String.LocalizationValue(result.info?.displayName ?? "result.title")))
            )
            
        }
    }
    
    @ViewBuilder
    private var resultUserdataSection: some View {
        Section {
            HStack {
                Text(LocalizedStringKey("result.userData.name"))
                Spacer()
                TextField(
                    LocalizedStringKey("result.userData.name.placeholder"),
                    text: $cardUserName
                )
                .multilineTextAlignment(.trailing)
            }
            .onAppear {
                if let name = result.info?.displayName, !name.isEmpty {
                    cardUserName = name
                }
            }
            .onChange(of: cardUserName) { _, newValue in
                guard var info = result.info else {
                    return
                }

                info.displayName = newValue
                result.info = info
                if !scandata {
                    saveAction()
                }
            }

            HStack {
                Picker(
                    LocalizedStringKey("result.userData.design"),
                    selection: $cardDesign
                ) {
                    ForEach(cardDesignList, id: \.self) { design in
                        if design.type == result.converter {
                            HStack(spacing: 3) {
                                CardImage(name: design.imageName)
                                Text(
                                    LocalizedStringKey(design.name)
                                )
                            }
                            .tag(Optional(design))
                        }
                    }
                }
                .pickerStyle(.navigationLink)
            }
            .onChange(of: cardDesign) { _, newValue in
                guard var info = result.info else {
                    return
                }

                info.iconName = newValue?.imageName
                result.info = info
                if !scandata {
                    saveAction()
                }
            }
        }
        .padding(.horizontal)
        .listRowInsets(
            .init(
                top: .zero,
                leading: .zero,
                bottom: .zero,
                trailing: .zero
            )
        )
    }

    @ViewBuilder
    private var resultInfoSection: some View {
        Section(
            header: Text(LocalizedStringKey("result.info")),
            footer: Text(
                String(localized: "result.description.common") +
                String(
                    localized: String.LocalizationValue(result.description)
                )
            )
        ) {
            if let info = result.info {
                resultInfoContent(info)
            } else {
                Text(LocalizedStringKey("result.info.empty"))
            }
        }
    }

    @ViewBuilder
    private func resultInfoContent(
        _ info: ResultCardInfo
    ) -> some View {
        let display = result.converter.cardInfo(info)
        let balance = result.balance ?? 0
        let balanceText = balance.balanceText
        let currency = localizedCurrency(info.currency)

        Group {
            HStack {
                Text(LocalizedStringKey("result.info.balance"))
                Spacer()
                Text("\(balanceText) \(currency)")
            }
            
            HStack {
                Text(LocalizedStringKey("result.info.cardCategory"))
                Spacer()
                Text(
                    String(localized: String.LocalizationValue(display.nameShort))
                )
                .foregroundStyle(Color.gray)
                .textSelection(.enabled)
                .onAppear() {
                    if cardUserName == "" {
                        cardUserName = String(localized: String.LocalizationValue(display.nameShort))
                    }
                }
            }
            
            if !display.type.isEmpty {
                HStack {
                    Text(LocalizedStringKey("result.info.cardType"))
                    Spacer()
                    Text(String(localized: String.LocalizationValue(display.type)))
                        .foregroundStyle(Color.gray)
                        .textSelection(.enabled)
                        .onAppear() {
                            setCardDesigin(display.type)
                            
                            if cardUserName == "" || (cardUserName == String(localized: String.LocalizationValue(display.nameShort))) {
                                cardUserName = String(localized: String.LocalizationValue(display.type))
                            }
                        }
                }
            }
            
            if !display.idm.isEmpty {
                HStack {
                    Text(LocalizedStringKey("result.info.ID"))
                    Spacer()
                    Text(display.idm)
                        .foregroundStyle(Color.gray)
                        .textSelection(.enabled)
                }
            } else {
                Text(LocalizedStringKey("result.info.empty"))
            }
        }
        .onAppear() {
            if display.type.isEmpty {
                setCardDesigin("")
            }
        }
    }

    @ViewBuilder
    private var resultHistorySection: some View {
        Section(
            header: Text(
                "result.history.balance:\(result.history?.count ?? 0)"
            )
        ) {
            if result.isHistory {
                if let history = result.history {
                    resultHistoryList(history)
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
        }
    }

    @ViewBuilder
    private func resultHistoryList(
        _ history: [ResultHistory]
    ) -> some View {
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
    }

    @ViewBuilder
    private func resultHistoryRow(
        index: Int,
        item: ResultHistory,
        history: [ResultHistory]
    ) -> some View {
        let currency = localizedCurrency(
            result.info?.currency ?? ""
        )

        let display = result.converter.history(item)

        let hasNext = index + 1 < history.count

        let nextBalance: Double =
            hasNext
                ? history[index + 1].balance
                : 0

        let diff: Double? =
            hasNext
                ? item.balance - nextBalance
                : (result.isLastHide ? nil : item.balance)

        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            HStack {
                Text(
                    String(
                        localized: String.LocalizationValue(
                            display.processType
                        )
                    )
                )
                .font(.headline)

                Spacer()

                Text(display.date)
                    .foregroundStyle(Color.gray)
            }

            HStack(spacing: 2) {
                if let diff {
                    resultHistoryAmount(
                        diff: diff,
                        currency: currency
                    )
                }

                Spacer()

                let balanceText =
                    display.balance.balanceText

                Text("\(balanceText) \(currency)")
            }
        }
    }

    @ViewBuilder
    private func resultHistoryAmount(
        diff: Double,
        currency: String
    ) -> some View {
        if diff == 0 {
            Text("0 \(currency)")
                .foregroundStyle(.green)
        } else {
            let sign = diff >= 0 ? "+" : "-"
            let amount = abs(diff).balanceText

            Text("\(sign)\(amount) \(currency)")
                .foregroundStyle(
                    diff >= 0
                        ? .green
                        : .red
                )
        }
    }

    private func localizedCurrency(
        _ currency: String,
    ) -> String {
        String(
            localized: String.LocalizationValue(currency)
        )
    }

    private func saveAction() {
        do {
            try ResultSave.save(
                result,
                in: modelContext
            )

            print("Resultの保存に成功しました")
        } catch {
            print("Resultの保存に失敗しました: \(error)")
        }
        
        saveListID = UUID()
    }
    
    private func setCardDesigin(_ name: String?) {
        if let iconName = result.info?.iconName,
           let design = cardDesignList.first(where: {
               $0.imageName == iconName
           }) {
            cardDesign = design
        } else if let design = (cardDesignList.first { $0.name == name }) {
            cardDesign = design
        } else if let design = (cardDesignList.first { $0.type == result.converter && $0.isDefault }) {
            cardDesign = design
        } else {
        }
    }
}
