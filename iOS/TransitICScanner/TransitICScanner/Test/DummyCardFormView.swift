import SwiftUI

struct DummyCardFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State var result:Result = Result(isHistory: false, converter: .jpIC, isLastHide: false, description: "", savedAt: Date.now)
    @State var history:[ResultHistory] = []
    @State var info:ResultCardInfo = ResultCardInfo(idm: "", name: "", nameShort: "", currencyType:
        .usd, type: "")
    
    @State var balance: Double = 0.0
    @State var isHistory:Bool = false
    @State var nameShort: String = ""
    @State var currency: currencyType = .usd
    @State var type: String = ""
    @State var idm: String = String(Int.random(in: 100000000000...999999999999))
    @State var converter:ConverterType = .jpIC
    
    @State var isHistoryForm:Bool = false
    @State var newHistory:ResultHistory = ResultHistory(processType: 0x00, date: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date()), balance: 0.0, lineIn: 0x00, stationIn: 0x00, lineOut: 0x00, stationOut: 0x00, transactionId: 0)
    let emptyHistory:ResultHistory = ResultHistory(processType: 0x00, date: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date()), balance: 0.0, lineIn: 0x00, stationIn: 0x00, lineOut: 0x00, stationOut: 0x00, transactionId: 0)
    
    @State var isDone = false
    
    @Binding var deleteAds:Bool
    
    var body: some View {
        List {
            Section(header: Text(LocalizedStringKey("result.info"))) {
                ListFormTextView(isRequest: true, title: "result.info.cardCategory", placeholder: "result.userData.name.placeholder", value: $nameShort)
                ListFormTextView(isRequest: false, title: "result.info.cardType", placeholder: "result.info.cardType", value: $type)
                Picker(LocalizedStringKey("setting.debug.result.dummyCard.form.currency"),selection: $currency) {
                    ForEach(currencyType.allCases, id: \.self) { item in
                        Text(String("\(item)")).tag(item)
                    }
                }
                ListFormTextView(isRequest: false, title: "result.info.ID", placeholder: "1A2B3C4D5", value: $idm)
                ListFormNumberView(isRequest: true, title: "result.info.balance", placeholder: "0", value: $balance)
                Picker(LocalizedStringKey("setting.debug.result.dummyCard.form.converter"),selection: $converter) {
                    ForEach(ConverterType.allCases, id: \.self) { item in
                        Text(String("\(item)")).tag(item)
                    }
                }
            }
            
            Section() {
                Toggle(isOn: $isHistory) {
                    Text(LocalizedStringKey("setting.debug.result.dummyCard.form.isHistory"))
                }
                if isHistory {
                    ForEach(history,id:\.self) { item in
                        HStack {
                            HStack(spacing:1) {
                                Text(String(item.date.year ?? 0))
                                Text(String("/"))
                                Text(String(item.date.month ?? 0))
                                Text(String("/"))
                                Text(String(item.date.day ?? 0))
                            }
                            Spacer()
                            VStack(alignment:.trailing) {
                                HStack {
                                    Text(LocalizedStringKey("setting.debug.result.dummyCard.form.history.balance"))
                                    Text(String(item.balance))
                                }
                                HStack {
                                    Text(LocalizedStringKey("setting.debug.result.dummyCard.form.history.amount"))
                                    Text(String(item.amount ?? 0))
                                }
                            }
                            .foregroundStyle(Color.gray)
                            .font(.caption)
                        }
                    }
                    .onDelete(perform: removeHistory)
                    
                    NavigationLink(LocalizedStringKey("setting.debug.result.dummyCard.form.history.add"), destination: DummyHistoryFormView(isHistoryForm:$isHistoryForm, newHistory: $newHistory))
                        .foregroundStyle(Color.accentColor)
                        .onChange(of:newHistory) {
                            if newHistory != emptyHistory {
                                history.append(newHistory)
                                newHistory = emptyHistory
                            }
                        }
                }
            }
            
            Button(action: {
                sendData()
                isDone = true
            }) {
                Text(LocalizedStringKey("setting.debug.result.dummyCard.form.done"))
                    .foregroundStyle(Color.accentColor)
            }
            .navigationDestination(isPresented: $isDone) {
                ResultView(result: result, scandata: true, saveListID: .constant(UUID()), deleteAds: $deleteAds)
            }
        }
        .navigationTitle(LocalizedStringKey("setting.debug.result.dummyCard"))
    }
    private func sendData() {
        if idm == "" {
            idm = String(Int.random(in: 100000000000...999999999999))
        }
        if nameShort == "" {
            nameShort = "DEBUG"
        }
        
        
        info = ResultCardInfo(idm: idm, name: "DEBUG", nameShort: nameShort, currency: currency.rawValue, type: type)
        result = Result(
            balance: balance,
            isHistory: isHistory,
            history: history,
            info: info,
            converter: converter,
            isLastHide: false,
            description: "DEBUG CARD",
            savedAt: Date.now
        )
    }
    private func removeHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
    }
}

struct DummyHistoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isHistoryForm:Bool
    @Binding var newHistory:ResultHistory
    @State var processType:String = ""
    @State var date:Date = Date()
    @State var balance:Double = 0.0
    @State var amount:Double = 0.0
    var body: some View {
        List {
            Section() {
                ListFormTextView(isRequest: true, title: "setting.debug.result.dummyCard.form.history.processType", placeholder: "0x00", value: $processType)
                DatePicker(LocalizedStringKey("setting.debug.result.dummyCard.form.history.date"),selection: $date,displayedComponents: [.date, .hourAndMinute])
                ListFormNumberView(isRequest: false, title: "setting.debug.result.dummyCard.form.history.balance", placeholder: "0", value: $balance)
                ListFormNumberView(isRequest: false, title: "setting.debug.result.dummyCard.form.history.amount", placeholder: "0", value: $amount)
            }
            Section() {
                Button(action: {
                let calendar = Calendar.current
                newHistory = ResultHistory(processType: UInt8(processType) ?? 0x00, date: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date), balance: balance,amount:Double?(amount), lineIn: 0x00, stationIn: 0x00, lineOut: 0x00, stationOut: 0x00, transactionId: 0)
                    isHistoryForm = false
                    dismiss()
                }) {
                    Text(LocalizedStringKey("setting.debug.result.dummyCard.form.done"))
                }
            }
        }
    }
}

struct ListFormTextView: View {
    @State var isRequest:Bool
    @State var title:String
    @State var placeholder:String
    @Binding var value:String
    var body: some View {
        HStack {
            HStack(spacing:2) {
                Text(LocalizedStringKey(title))
                if isRequest {
                    Text("setting.debug.result.dummyCard.form.request")
                        .foregroundStyle(.red)
                }
            }
            Spacer()
            TextField(LocalizedStringKey(placeholder),text:$value)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ListFormNumberView: View {
    @State var isRequest:Bool
    @State var title:String
    @State var placeholder:String
    @Binding var value:Double
    var body: some View {
        HStack {
            HStack(spacing:2) {
                Text(LocalizedStringKey(title))
                if isRequest {
                    Text("setting.debug.result.dummyCard.form.request")
                        .foregroundStyle(.red)
                }
            }
            Spacer()
            TextField(LocalizedStringKey(placeholder),value:$value, format: .number)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
        }
    }
}


#Preview {
    DummyCardFormView(deleteAds: .constant(false))
}
