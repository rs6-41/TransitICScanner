import SwiftUI
import Combine
import SwiftUI

//MARK: EasyCard(旧式・スクレイピング)
//MIFARE Classicかつ暗号化領域で読み取れないためスクレイピングで取得
let twEasyCard_old:CardInfo = CardInfo(
    logo:"twEasyCard_old",
    name:"card.web.twEasyCard_old",
    sortName:"cardList.twEasyCard_old.sortName",
    area: .tw,
    countryCode: ["tw"],
    description: "card.web.twEasyCard_old.description",
    scand_description: "twEasyCard_old.scand.description",
    searchWords: ["cardList.area.tw","youyouka","ㄧㄡㄧㄡˊㄎㄚˇ"],
    scanOption: ScanOption(
        name:"twEasyCard_old",
        nameShort:"twEasyCard_old.short",
        scanType: .scraping,
        pollingOption:[],
        felicaSystemCodes:[],
        url: URL(string:"https://ezweb.easycard.com.tw/search/")!,
        historyCount:999,
        currency:"currency.twd",
        converter:.twEasyCard_old,
        scrapingView: {
            AnyView(twEasyCard_old_View())
        }
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance:980.0,
            idm:"7462640446",
            type:"",
            history: [
            // 2: +500TWD 台北站でチャージ 残高1000TWD 2025/19/23 19:21
            ResultHistory(processType: 0x00,date: sampleDay2,balance: 1000,amount: 500,lineIn: 0x00,stationIn: 0x00,lineOut: 0x00,stationOut: 0x00,transactionId: 1,mappingID: "台北站"),
            // 3: 20TWD 台北站 残高980TWD 2026/1/3 12:58
            ResultHistory(processType: 0x00,date: sampleDay3,balance: 980,amount: 20,lineIn: 0x00,stationIn: 0x00,lineOut: 0x00,stationOut: 0x00,transactionId: 152,mappingID: "台北站"),
            ]
        )
)

struct twEasyCard_old_View: View {
    let item: CardInfo = twEasyCard_old
    @Environment(\.dismiss) private var dismiss
    @StateObject private var controller = twEasyCard_old_scraping()
    @State private var result: Result?
    @State private var navigationResult: Result?
    @State var scannedNumber:String? = ""
    @State var error = false
    @State var errorMessage = ""
    
    @State var name:String = ""
    @State var card: String = ""
    @State var birthday: String = ""
    @State var birthdayMonth: String = ""
    @State var birthdayDay: String = ""
    @State var captcha: String = ""
    @State var isLoaded: Bool = false
    @State var isLoading: Bool = false
    @State var cardLimit:Int = 16
    @State var captchaLimit:Int = 6
    
    @AppStorage("deleteAds") var deleteAds = false

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header:Text(LocalizedStringKey("form.card.title")),
                    footer:Text(LocalizedStringKey("form.card.description"))
                ){
                    TextField(String("0123456789"), text: $card)
                        .keyboardType(.numberPad)
                        .onChange(of: card) {
                            if card.count > cardLimit {
                                card = String(card.prefix(cardLimit))
                            }
                        }
                }
                Section(
                    header:Text(LocalizedStringKey("form.birthday.title")),
                    footer:Text(LocalizedStringKey("form.birthday.description"))
                ){
                    HStack {
                        TextField(LocalizedStringKey("form.birthday.month"), text: $birthdayMonth)
                            .keyboardType(.numberPad)
                            .onChange(of: birthdayMonth) {
                                let limit = 2
                                if birthdayMonth.count > limit {
                                    birthdayMonth = String(birthdayMonth.prefix(limit))
                                }
                            }
                        Divider()
                        TextField(LocalizedStringKey("form.birthday.day"), text: $birthdayDay)
                            .keyboardType(.numberPad)
                            .onChange(of: birthdayDay) {
                                let limit = 2
                                if birthdayDay.count > limit {
                                    birthdayDay = String(birthdayDay.prefix(limit))
                                }
                            }
                    }
                }
                Section(
                    header:Text(LocalizedStringKey("form.captcha.title")),
                    footer:Text(LocalizedStringKey("form.captcha"))
                ){
                    VStack(alignment:.leading) {
                        if let image = controller.captchaImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width:250)
                                .padding(.bottom,5)
                                .onAppear() {
                                    isLoaded = true
                                }
                        } else {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .onAppear() {
                                        isLoaded = false
                                    }
                                Spacer()
                            }
                        }
                        TextField(String("012345"), text: $captcha)
                            .keyboardType(.numberPad)
                            .onChange(of: captcha) {
                                if captcha.count > captchaLimit {
                                    captcha = String(captcha.prefix(captchaLimit))
                                }
                            }
                    }
                }
                .listSectionSpacing(15)
                
                Section(footer:Text(LocalizedStringKey("form.description.scraping.easycard"))) {
                    Button(action: {
                        onSubmit()
                    }) {
                        Text(LocalizedStringKey("form.done"))
                            .bold()
                            .padding()
                            .frame(maxWidth:.infinity,maxHeight:30)
                    }
                    .disabled(!isLoaded)
                    .buttonStyle(GlassProminentButtonStyle())
                    .frame(maxWidth:400,alignment:.center)
                    .padding(.bottom)
                }
                .listRowInsets(
                    .init(top: .zero,leading: .zero,bottom: .zero,trailing: .zero)
                )
                .listRowBackground(Color.clear)
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()
                        ProgressView()
                            .controlSize(.large)
                            .padding(24)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .navigationTitle(LocalizedStringKey(item.name))
            .navigationDestination(item: $navigationResult) { result in
                ResultView(result: result, scandata: true, saveListID: .constant(UUID()), deleteAds: $deleteAds)
                    .navigationBarBackButtonHidden()
            }
            .toolbar {
                ToolbarItem(placement:.cancellationAction){
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName:"xmark")
                    }
                }
            }
            .onAppear {
                Task {
                    await controller.loadCaptcha(baseURL: item.scanOption.url!.deletingLastPathComponent())
                }
            }
            .alert(LocalizedStringKey("error"), isPresented: $error) {
                Button(action: {
                    errorMessage = ""
                }) {
                    Text(LocalizedStringKey("error.ok"))
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    func onSubmit() {
        birthday = birthdayMonth + birthdayDay
        if card == "" || card.isEmpty {
            errorMessage = String(localized:"twEasyCard_old.form.error.card.empty")
            error = true
        } else if card.count != 10 && card.count != 16 {
            errorMessage = String(localized:"twEasyCard_old.form.error.card.count")
            error = true
        } else if captcha == "" || captcha.isEmpty {
            errorMessage = String(localized:"twEasyCard_old.form.error.captcha.empty")
            error = true
        } else if captcha.count != 6 {
            errorMessage = String(localized:"twEasyCard_old.form.error.captcha.count")
            error = true
        } else if birthday.count != 0 && birthday.count == 4 {
            errorMessage = String(localized:"twEasyCard_old.form.error.birthday.count")
            error = true
        } else {
            postData()
        }
    }
    func postData() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            do {
                try await controller.verifyCaptcha(captcha: captcha)
                let html = try await controller.search(cardID: card, birthday: birthday, checkword: captcha)
                print("[EasyCard] Checking latest response HTML length: \(html.count)")

                if let serverMessage = controller.extractServerAlert(from: html) {
                    await controller.loadCaptcha(baseURL: item.scanOption.url!.deletingLastPathComponent())
                    
            //エラーハンドリング(サーバー側)
            await MainActor.run {
                isLoading = false
                captcha = ""
                error = false
                switch serverMessage {
                case "非悠遊卡號":
                    errorMessage = String(localized: "twEasyCard_old.error.server.invalid.card")
                case "驗證碼未通過":
                    errorMessage = String(localized: "twEasyCard_old.error.server.invalid.captcha")
                case "記名卡請輸入正確生日，非記名卡生日欄位無須填寫":
                    errorMessage = String(localized: "twEasyCard_old.error.server.invalid.birthday")
                case "請輸入正確起迄日期":
                    errorMessage = String(localized: "twEasyCard_old.error.server.invalid.date")
                case "語音播放次數已達上限":
                    errorMessage = String(localized: "twEasyCard_old.error.server.invalid.audio")
                default:
                    errorMessage = serverMessage
                }
                DispatchQueue.main.async {
                    error = true
                }
            }
            return
                }

                print("[EasyCard] HTML length: \(html.count)")
                
                guard let parsed = controller.parseEasyCardResult(html: html, cardID: card) else {
                    print("[EasyCard] Failed to create Result")
                    return
                }
                
                await MainActor.run {
                    isLoading = false
                    print("[EasyCard] Navigate ResultView history count: \(parsed.history?.count ?? 0)")
                    result = parsed
                    navigationResult = parsed
                }
            } catch {
                if let serverError = error as? EasyCardServerError {
                    await controller.loadCaptcha(baseURL: item.scanOption.url!.deletingLastPathComponent())
                    await MainActor.run {
                        captcha = ""
                        isLoading = false
                        switch serverError {
                        case .server(let message):
                            switch message {
                            case "驗證碼未通過":
                                errorMessage = String(localized: "twEasyCard_old.error.server.invalid.captcha")
                            case "Token無效":
                                errorMessage = String(localized: "twEasyCard_old.error.server.invalid.retry")
                            default:
                                errorMessage = message
                            }
                        }
                        self.error = true
                    }
                    return
                }
                await MainActor.run {
                    isLoading = false
                }
                print("Error during submission: \(error)")
            }
        }
    }
}


final class twEasyCard_old_scraping: ObservableObject {
    private let baseURL = twEasyCard_old.scanOption.url!
    @Published var captchaImage: UIImage?
    @Published var captchaToken: String = ""
    @Published var cookies: [HTTPCookie] = []
    @Published var htmlResult: String = ""

    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        return URLSession(configuration: config)
    }

    func loadCaptcha(baseURL: URL) async {
        do {
            // 1. GET CardSearch.php to get cookies
            let cardSearchURL = self.baseURL.appendingPathComponent("CardSearch.php")
            var cardSearchRequest = URLRequest(url: cardSearchURL)
            cardSearchRequest.httpMethod = "GET"
            let (cardSearchData, cardSearchResponse) = try await session.data(for: cardSearchRequest)
            if let httpResponse = cardSearchResponse as? HTTPURLResponse,
               let headerFields = httpResponse.allHeaderFields as? [String: String],
               let url = httpResponse.url {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
                HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
                self.cookies = HTTPCookieStorage.shared.cookies ?? []
            }

            // 2. GET captcha.php to get captcha image and token
            let captchaURL = self.baseURL.appendingPathComponent("captcha.php")
            var captchaRequest = URLRequest(url: captchaURL)
            captchaRequest.httpMethod = "GET"
            let (captchaData, captchaResponse) = try await session.data(for: captchaRequest)
            if let httpResponse = captchaResponse as? HTTPURLResponse {
                if let token = httpResponse.value(forHTTPHeaderField: "X-Captcha-Token") {
                    DispatchQueue.main.async {
                        self.captchaToken = token
                    }
                }
            }
            if let image = UIImage(data: captchaData) {
                DispatchQueue.main.async {
                    self.captchaImage = image
                }
            } else {
                print("Failed to decode captcha image data")
            }
        } catch {
            print("Error loading captcha: \(error)")
        }
    }

    func verifyCaptcha(captcha: String) async throws {
        // Print all cookies before request
        if let cookies = HTTPCookieStorage.shared.cookies, !cookies.isEmpty {
            print("[EasyCard] Cookies before verifyCaptcha:")
            for cookie in cookies {
                print("  Cookie: \(cookie.name) = \(cookie.value)")
            }
        } else {
            print("[EasyCard] No cookies before verifyCaptcha")
        }
        let verifyURL = self.baseURL.appendingPathComponent("captcha_verify.php")
        var request = URLRequest(url: verifyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let jsonBody: [String: String] = [
            "captcha": captcha,
            "token": captchaToken
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        let session = URLSession(configuration: config)
        let (data, response) = try await session.data(for: request)

        // Print HTTP status captcha and headers
        if let httpResponse = response as? HTTPURLResponse {
            print("[EasyCard] verifyCaptcha status code: \(httpResponse.statusCode)")
            print("[EasyCard] verifyCaptcha response headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("  \(key): \(value)")
            }
        }

        // Print response body as UTF-8 text if possible
        if let text = String(data: data, encoding: .utf8) {
            print("[EasyCard] verifyCaptcha response body:\n\(text)")
        } else {
            print("[EasyCard] verifyCaptcha response body could not be decoded as UTF-8")
        }

        // Parse JSON and print dictionary
        guard let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("[EasyCard] verifyCaptcha: Failed to parse JSON")
            throw URLError(.cannotParseResponse)
        }
        print("[EasyCard] verifyCaptcha JSON dictionary: \(jsonObj)")
        // Print message field if present
        if let message = jsonObj["message"] as? String {
            print("[EasyCard] Captcha message: \(message)")
        }
        guard (jsonObj["success"] as? Bool) == true else {
            let message = (jsonObj["message"] as? String) ?? "Unknown Error"
            throw EasyCardServerError.server(message)
        }
    }

    func search(cardID: String, birthday: String, checkword: String, period: String = "date1y") async throws -> String {
        // Print all cookies before request
        if let cookies = HTTPCookieStorage.shared.cookies, !cookies.isEmpty {
            print("[EasyCard] Cookies before search:")
            for cookie in cookies {
                print("  Cookie: \(cookie.name) = \(cookie.value)")
            }
        } else {
            print("[EasyCard] No cookies before search")
        }
        let searchURL = self.baseURL.appendingPathComponent("CardSearch.php")
        var request = URLRequest(
            url: searchURL,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 30
        )
        request.httpMethod = "POST"
        let calendar = Calendar(identifier: .gregorian)
        let endDate = calendar.date(byAdding: .day, value: -1, to: Date())!
        let startDate = calendar.date(byAdding: .day, value: -364, to: endDate)!

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)

        let bodyComponents = [
            "Cont=Cont",
            "card_id=\(cardID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cardID)",
            "birthday=\(birthday.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? birthday)",
            "date=date1y",
            "START_DATE=\(startString)",
            "END_DATE=\(endString)",
            "checkword=\(checkword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? checkword)"
        ]
        let bodyString = bodyComponents.joined(separator: "&")
        // Print the complete form body string being sent
        print("[EasyCard] search POST body: \(bodyString)")
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        let session = URLSession(configuration: config)
        let (data, response) = try await session.data(for: request)

        // Print HTTP status captcha and headers
        if let httpResponse = response as? HTTPURLResponse {
            print("[EasyCard] search status code: \(httpResponse.statusCode)")
            print("[EasyCard] search response headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("  \(key): \(value)")
            }
        }

        if let htmlString = String(data: data, encoding: .utf8) {
            // Print first 4000 characters of HTML response
            let preview = htmlString.prefix(4000)
            print("[EasyCard] search HTML response (first 4000 chars):\n\(preview)")

            print("[EasyCard] contains pg1: \(htmlString.contains("id=\"pg1\""))")
            print("[EasyCard] contains transaction header: \(htmlString.contains("交易時間"))")
            print("[EasyCard] contains code text: \(htmlString.contains("驗證"))")
            print("[EasyCard] contains input prompt: \(htmlString.contains("請輸入"))")

            // Check for <script>alert( and window.alert(
            let patterns = [
                #"<script>\s*alert\(['"](.+?)['"]\)"#,
                #"window\.alert\(['"](.+?)['"]\)"#
            ]
            var foundAlert = false
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                    let matches = regex.matches(in: htmlString, options: [], range: NSRange(location: 0, length: htmlString.utf16.count))
                    for match in matches {
                        if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: htmlString) {
                            let alertText = String(htmlString[range])
                            print("[EasyCard] Server alert: \(alertText)")
                            foundAlert = true
                        }
                    }
                }
            }
            if !foundAlert {
                // Detect window.alert( even if not matching the above
                if htmlString.contains("window.alert(") {
                    print("[EasyCard] Detected window.alert( in response HTML")
                }
            }
            
            self.htmlResult = htmlString
            print("HTML result received:\n\(htmlString)")
            return htmlString
        } else {
            print("Failed to decode HTML response")
            return ""
        }
    }

    func parseEasyCardResult(html: String, cardID: String) -> Result? {
        guard !html.isEmpty else { return nil }
        var histories: [ResultHistory] = []
        do {
            let rowPattern = #"<tr\s+class=['\"]r1['\"]>(.*?)</tr>"#
            let rowRegex = try NSRegularExpression(pattern: rowPattern, options: [.dotMatchesLineSeparators])
            let tdPattern = #"<td[^>]*>(.*?)</td>"#
            let tdRegex = try NSRegularExpression(pattern: tdPattern, options: [])
            let nsrange = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = rowRegex.matches(in: html, options: [], range: nsrange)
            var index = 0
            let calendar = Calendar.current
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            for match in matches {
                if let rowRange = Range(match.range(at: 1), in: html) {
                    let rowHTML = String(html[rowRange])
                    let tdNSRange = NSRange(rowHTML.startIndex..<rowHTML.endIndex, in: rowHTML)
                    let tdMatches = tdRegex.matches(in: rowHTML, options: [], range: tdNSRange)
                    guard tdMatches.count >= 10 else { continue }
                    var columns: [String] = []
                    for tdMatch in tdMatches {
                        if let tdRange = Range(tdMatch.range(at: 1), in: rowHTML) {
                            let tdContent = String(rowHTML[tdRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                            columns.append(tdContent)
                        }
                    }
                    guard columns.count >= 10 else { continue }
                    // Parse date from column0
                    guard let parsedDate = dateFormatter.date(from: columns[0]) else { continue }
                    let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: parsedDate)
                    // Map processType from column1
                    let processText = columns[1]
                    let processType: Int
                    if processText.contains("扣款") {
                        processType = 1
                    } else if processText.contains("加值") {
                        processType = 2
                    } else {
                        processType = 0
                    }
                    // Parse amount from column3
                    var amount = Double(columns[3].replacingOccurrences(of: ",", with: "")) ?? 0.0
                    // Parse balance from column4
                    let balance = Double(columns[4].replacingOccurrences(of: ",", with: "")) ?? 0.0
                    
                    if processType == 1 {
                        amount = -amount
                    }
                    let history = ResultHistory(
                        processType: UInt8(processType),
                        date: dateComponents,
                        balance: balance,
                        amount: amount,
                        lineIn: 0,
                        stationIn: 0,
                        lineOut: 0,
                        stationOut: 0,
                        transactionId: index
                    )
                    histories.append(history)
                    index += 1
                    print("[EasyCard] Parsed history: date=\(columns[0]), type=\(columns[1]), amount=\(amount), balance=\(balance)")
                }
            }
            // Sort histories by date descending and reassign transactionId
            histories.sort { first, second in
                let firstDate = Calendar.current.date(from: first.date) ?? .distantPast
                let secondDate = Calendar.current.date(from: second.date) ?? .distantPast
                return firstDate < secondDate
            }

            histories = histories.enumerated().map { index, history in
                ResultHistory(
                    processType: history.processType,
                    date: history.date,
                    balance: history.balance,
                    amount: history.amount,
                    lineIn: history.lineIn,
                    stationIn: history.stationIn,
                    lineOut: history.lineOut,
                    stationOut: history.stationOut,
                    transactionId: index
                )
            }

            let cardInfo = ResultCardInfo(
                idm: cardID,
                name: "EasyCard",
                nameShort: "EasyCard",
                currency: "TWD",
                type: "",
                serial: nil,
                version: nil,
                validDate: nil
            )
            let balance = histories.last?.balance ?? 0.0
            let result = Result(
                balance: balance,
                isHistory: true,
                history: histories,
                info: cardInfo,
                converter: .twEasyCard_old,
                isLastHide: false,
                description: twEasyCard_old.scand_description
            )
            return result
        } catch {
            print("Error parsing EasyCard result: \(error)")
            return nil
        }
    }

    func extractServerAlert(from html: String) -> String? {
        let pattern = #"<script[^>]*>\s*(?:window\.)?alert\(\s*['\"]([^'\"]+)['\"]\s*\)\s*</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        // Insert logic to check if the matched <script> is immediately before </body>
        if let bodyRange = html.range(of: "</body>", options: .caseInsensitive),
           let scriptRange = html.range(of: "</script>", options: .backwards) {
            if scriptRange.upperBound > bodyRange.lowerBound {
                print("[EasyCard] Last <script> is not immediately before </body>")
                return nil
            }
            let between = html[scriptRange.upperBound..<bodyRange.lowerBound]
            if between.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                print("[EasyCard] Content exists between </script> and </body>")
                return nil
            }
        }
        guard let match = matches.last,
              let messageRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        print("[EasyCard] Matched server alert: \(String(html[messageRange]))")
        return String(html[messageRange])
    }
}


enum EasyCardServerError: LocalizedError {
    case server(String)

    var errorDescription: String? {
        switch self {
        case .server(let message):
            return message
        }
    }
}
