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
    @Binding var deleteAds:Bool

    var body: some View {
        NavigationStack {
            List {
                resultUserdataSection
                resultInfoSection
                ListAdView(deleteAds:$deleteAds)
                resultHistorySection
            }
            .onAppear() {
                setDefaultDisplayName()
            }
            .onChange(of:cardUserName) {
                setDefaultDisplayName()
            }
            .toolbar {
                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    if scandata {
                        Button(action: {
                            saveAction()
                            dismiss()
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
                Text(cardUserName)
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
                                Text(LocalizedStringKey(design.name))
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
        Section {
            if let info = result.info {
                resultInfoContent(info)
            } else {
                Text(LocalizedStringKey("result.info.empty"))
            }
        } header: {
            Text(LocalizedStringKey("result.info"))
        } footer: {
            VStack(alignment:.leading, spacing:0) {
                Text(LocalizedStringKey("result.description.common"))
                Text(LocalizedStringKey(result.description))
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
        

        Group {
            HStack {
                Text(LocalizedStringKey("result.info.balance"))
                Spacer()
                HStack(spacing:0) {
                    Text(String("\(balanceText)"))
                    if let currency = info.currencyType?.getLocalize() {
                        Text(currency)
                    }
                }
            }
            
            HStack {
                Text(LocalizedStringKey("result.info.cardCategory"))
                Spacer()
                Text(LocalizedStringKey(display.nameShort))
                    .foregroundStyle(Color.gray)
                    .textSelection(.enabled)
            }
            
            if !display.type.isEmpty {
                HStack {
                    Text(LocalizedStringKey("result.info.cardType"))
                    Spacer()
                    Group {
                        if display.typeLocalizeTable != "" {
                            Text(String(localized: String.LocalizationValue(display.type), table: display.typeLocalizeTable))
                        } else {
                            Text(String(localized: String.LocalizationValue(display.type)))
                        }
                    }
                        .foregroundStyle(Color.gray)
                        .textSelection(.enabled)
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
            }
            if let savedAt = result.savedAt {
                HStack {
                    Text(LocalizedStringKey("result.info.date"))
                    Spacer()
                    Text(savedAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                        .foregroundStyle(Color.gray)
                }
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
        Section {
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
        } header: {
            if let count = result.history?.count {
                Text(LocalizedStringKey("result.history.balance:\(count)"))
            } else {
                Text(LocalizedStringKey("result.history.balance"))
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
        let currency = result.info?.currencyType?.getLocalize()

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
                HStack(spacing:0) {
                    Text(String("\(balanceText)"))
                    if let currency {
                        Text(currency)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func resultHistoryAmount(
        diff: Double,
        currency: LocalizedStringKey?
    ) -> some View {
        if diff == 0 {
            HStack(spacing:0) {
                Text(String("0"))
                if let currency {
                    Text(currency)
                }
            }
                .foregroundStyle(.green)
        } else {
            let sign = diff >= 0 ? "+" : "-"
            let amount = abs(diff).balanceText

            HStack(spacing:0) {
                Text(String("\(sign)\(amount)"))
                if let currency {
                    Text(currency)
                }
            }
            .foregroundStyle(
                diff >= 0
                ? .green
                : .red
            )
        }
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
    
    func setDefaultDisplayName() {
        if cardUserName == "" {
            let displayName:String = result.info?.displayName ?? ""
            if displayName == "" {
                if let info = result.info {
                    cardUserName = result.converter.cardInfo(info).nameShort
                } else {
                    cardUserName = String(localized:"card")
                }
            } else {
                cardUserName = displayName
            }
        }
    }
}
