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
    var onDone: (() -> Void)? = nil
    var embedsNavigationStack = true
    
    @State var areaText:LocalizedStringKey = ""

    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack {
                    resultContent
                }
            } else {
                resultContent
            }
        }
    }

    private var resultContent: some View {
        List {
            #if !targetEnvironment(macCatalyst)
            ListAdView(deleteAds:$deleteAds)
            #endif
            resultUserdataSection
            resultInfoSection
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
                        if let onDone {
                            onDone()
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.white)
                    }
                    .tint(Color.accentColor)
                    .buttonStyle(.glassProminent)
                }
            }
        }
        .navigationTitle(Text(cardUserName))
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
            .onChange(of: cardUserName) {
                guard var info = result.info else {
                    return
                }
                if cardUserName != "" {
                    info.displayName = cardUserName
                    result.info = info
                    if !scandata {
                        saveAction()
                    }
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
            .onAppear() {
                if scandata {
                    if cardDesign == nil {
                        if let info = result.info {
                            let display = result.converter.cardInfo(info)
                            if !display.type.isEmpty {
                                cardDesign = cardDesignList.first {
                                    $0.type == result.converter && $0.name == display.type
                                }
                            }
                        }
                        
                        if cardDesign == nil {
                            cardDesign = cardDesignList.first {
                                $0.type == result.converter && $0.isDefault
                            }
                        }
                    }
                } else {
                    if let info = result.info {
                        cardDesign = cardDesignList.first {
                            $0.imageName == info.iconName
                        }
                    }
                }
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
        
        if let info = result.info {
            if let issueInfos = info.issueInfo {
                resultIssueContent(issueInfos)
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
                    if let currency = info.currencyType?.getLocalize(balanceText) {
                        Text(currency)
                    } else {
                        Text(balanceText)
                    }
                }
            }
            
            ListInfoContent(title:"result.info.cardCategory",value:LocalizedStringKey(display.nameShort))
            
            if !display.type.isEmpty && Localize(display.nameShort) != Localize(display.type) {
                HStack {
                    Text(LocalizedStringKey("result.info.cardType"))
                    Spacer()
                    Group {
                        if display.typeLocalizeTable != "" {
                            Text(String(localized: String.LocalizationValue(display.type), table: display.typeLocalizeTable))
                        } else {
                            Text(Localize(display.type))
                        }
                    }
                        .foregroundStyle(Color.gray)
                        .textSelection(.enabled)
                }
            }
            
            if !display.idm.isEmpty {
                ListInfoContent(title:"result.info.ID",rawValue:display.idm)
            }
            if let savedAt = result.savedAt {
                ListInfoContent(title:"result.info.date",rawValue:savedAt.formatted(date: .numeric, time: .shortened))
            }
        }
        .onAppear() {
            if display.type.isEmpty {
                setCardDesigin("")
            }
        }
    }
    
    @ViewBuilder
    private func resultIssueContent(
        _ issueInfo: issueInfo
    ) -> some View {
        
        Section() {
            ListInfoContent(title:"result.info.issueInfo.region",value:LocalizedStringKey(issueInfo.region))
            if areaText != "" {
                ListInfoContent(title:"result.info.issueInfo.prefecture",value:areaText)
            }
            if let otherAreaInfo = issueInfo.otherAreaInfo {
                ListInfoContent(title:"result.info.issueInfo.otherAreaInfo",value:LocalizedStringKey(otherAreaInfo))
            }
            if let issuer = issueInfo.issuer {
                ListInfoContent(title:"result.info.issueInfo.issuer",value:LocalizedStringKey(issuer))
            }
            if let date = issueInfo.date {
                ListInfoContent(title:"result.info.issueInfo.date",rawValue:date.formatted(date: .numeric, time: .shortened))
            }
            if let expiry = issueInfo.expiry {
                ListInfoContent(title:"result.info.issueInfo.expiry",rawValue:expiry.formatted(date: .numeric, time: .shortened))
            }
        } header: {
            Text(LocalizedStringKey("result.info.issueInfo"))
        }
        .onAppear() {
            if let area = issueInfo.area {
                if let city = issueInfo.city {
                    areaText = LocalizedStringKey("issue.cityNameLocalize:\(Localize(area)),\(Localize(city))")
                } else {
                    areaText = LocalizedStringKey(area)
                }
            } else if let city = issueInfo.city {
                areaText = LocalizedStringKey(city)
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
                if let diff {
                    let amount = resultHistoryAmount(diff: diff)
                    let currency = result.info?.currencyType?.getLocalize(amount)
                    Text(currency ?? LocalizedStringKey(amount))
                    .foregroundStyle(
                        diff >= 0
                        ? .green
                        : .red
                    )
                }

                Spacer()

                let balanceText =
                    display.balance.balanceText
                let currency = result.info?.currencyType?.getLocalize(balanceText)
                Text(currency ?? LocalizedStringKey(balanceText))
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
                    let display = result.converter.cardInfo(info)
                    if !display.type.isEmpty {
                        if display.typeLocalizeTable != "" {
                            cardUserName = String(localized: String.LocalizationValue(display.type), table: display.typeLocalizeTable)
                        } else {
                            cardUserName = Localize(display.type)
                        }
                    } else {
                        cardUserName = Localize(display.nameShort)
                    }
                } else {
                    cardUserName = String(localized:"card")
                }
            } else {
                cardUserName = displayName
            }
        }
    }
}

struct ListInfoContent: View {
    @State var title:LocalizedStringKey
    @State var value:LocalizedStringKey?
    @State var rawValue:String?
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Group {
                if let value {
                    Text(value)
                } else if let rawValue {
                    Text(rawValue)
                }
            }
            .foregroundStyle(Color.gray)
            .textSelection(.enabled)
        }
    }
}
