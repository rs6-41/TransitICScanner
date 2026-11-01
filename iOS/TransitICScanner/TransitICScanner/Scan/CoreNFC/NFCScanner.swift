import UIKit
import SwiftUI
@preconcurrency import CoreNFC
public import Combine

// 参考：https://qiita.com/treastrain/items/d54ef2c2abbcd40fb9f1
// 参考：https://github.com/metrodroid/metrodroid/wiki/FeliCa


struct ScanError {
    var code: NFCReaderError.Code?
    var message:String
}


final class NFCScannerModel: NSObject,ObservableObject, NFCTagReaderSessionDelegate {
    
    @Published var scanError:ScanError? = nil
    @Published var scanOption: ScanOption
    @Published var sessionActive: Bool = false
    @Published var result:Result? = nil
    
    var session: NFCTagReaderSession?
    var currentTag: NFCTag?
    
    init(scanOption: ScanOption) {
        self.scanOption = scanOption
        super.init()
    }
    
    //リーダーセッションの設定
    func readerSetup() {
        self.scanError = nil

        let configuration: NFCTagReaderSession.Configuration

        if scanOption.felicaSystemCodes != nil {
            configuration = NFCTagReaderSession.Configuration(
                pollingOption: scanOption.pollingOption,
                feliCaSystemCodes: scanOption.felicaSystemCodes ?? []
            )
        } else {
            configuration = NFCTagReaderSession.Configuration(
                pollingOption: scanOption.pollingOption
            )
        }

        self.session = NFCTagReaderSession(configuration: configuration, delegate: self)
        let cardName = scanOption.nameShort
        self.session?.alertMessage = String(
            format: String(localized: "scanner.coreNFC.scan.message"),
            Localize(cardName)
        )
        self.session?.begin()
    }
    
    // セッションがアクティブになった時
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        DispatchQueue.main.async {
            self.sessionActive = true
        }
    }
    
    // 読み取り後
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.sessionActive = false
            self.session = nil

            if let readerError = error as? NFCReaderError {
                if readerError.code.rawValue != 200 {
                    let error = "NFCReaderError\ncode: \(readerError.code.rawValue)\n\(readerError.localizedDescription)"
                    print(error)
                    self.scanError = ScanError(code: readerError.code, message: error)
                }
            } else {
                let error = "Unknown Error\n\(error.localizedDescription)"
                print(error)
                self.scanError = ScanError(code: .readerSessionInvalidationErrorSessionTerminatedUnexpectedly, message: error)
            }
        }
    }
    
    // 読み取り成功後
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print("tagReaderSession(_:didDetect:)")
        print("Detected tags: \(tags)")

        self.currentTag = tags.first
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag detected")
            return
        }

        // Inserted debug information for detected tag
        switch tag {
        case .miFare(let miFareTag):
            print("Detected NFCMiFareTag")
            print("Identifier: \(miFareTag.identifier.map { String(format: "%02X", $0) }.joined())")
            print("Family: \(miFareTag.mifareFamily.rawValue)")
            if let historical = miFareTag.historicalBytes {
                print("Historical: \(historical.map { String(format: "%02X", $0) }.joined(separator: " "))")
            }
        case .iso7816(let tag):

            print("Detected ISO7816")

            print(
                "initialSelectedAID:",
                tag.initialSelectedAID
            )

            print(
                "identifier:",
                tag.identifier
                    .map {
                        String(format: "%02X", $0)
                    }
                    .joined()
            )

            if let historicalBytes = tag.historicalBytes {
                print(
                    "historicalBytes:",
                    historicalBytes
                        .map {
                            String(format: "%02X", $0)
                        }
                        .joined(separator: " ")
                )
            }

            if let applicationData = tag.applicationData {
                print(
                    "applicationData:",
                    applicationData
                        .map {
                            String(format: "%02X", $0)
                        }
                        .joined(separator: " ")
                )
            }

            print(
                "proprietaryApplicationDataCoding:",
                tag.proprietaryApplicationDataCoding
            )
        case .feliCa:
            print("Detected FeliCa")
        case .iso15693:
            print("Detected ISO15693")
        @unknown default:
            print("Detected unknown tag")
        }

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            print("connect callback")

            if let error {
                print("Connect error:", error)
                DispatchQueue.main.async {
                    self.session?.invalidate(errorMessage: error.localizedDescription)
                }
                return
            }
            print("connect success")

            DispatchQueue.main.async {
                Task { @MainActor in
                    self.session?.alertMessage = String(localized: "scanner.coreNFC.scanning.message")
                    await self.switchCard(name: self.scanOption.name, tag, session)
                }
            }
        }
    }
    
}

extension NFCScannerModel {
    /// Dispatches scans to a reader-specific transport while keeping the
    /// card parser and result model owned by the scanner.
    func scanWithExternalReader(using manager: SmartCardManager) async throws {
        switch scanOption.name {
        case "jpIC", "jpIC_SAPICA", "jpIC_IruCa", "jpIC_icsca",
             "jpDoCard", "jpNplus", "jpOKICA", "jpRapica", "hkOctopus":
            try await scanFeliCaExternal(using: manager)
        case "usClipper":
            try await usClipper_scanExternal(using: manager)
        case "krOneCard":
            try await krOneCard_scanExternal(using: manager)
        case "cnTunion":
            try await cnTunion_scanExternal(using: manager)
        case "twICash":
            try await twICash_scanExternal(using: manager)
        default:
            throw ReaderError.message(
                String(localized: "cardList.reader.unsupported")
            )
        }
    }

    /// Reads FeliCa cards through readers that expose the card as an
    /// ISO 7816 smart card (the `FFCA` / `FFA4` / `FFB0` command set).
    private func scanFeliCaExternal(using manager: SmartCardManager) async throws {
        let result = try await manager.withCard { card in
            let reader = FeliCaExternalAPDU(transmit: manager.apduSender(for: card))
            let idmData = try await reader.send(0xCA, p1: 0x00, p2: 0x00, le: 256)
            guard idmData.count >= 8 else {
                throw ReaderError.message(String(localized: "error.smartCardReader.felicaIDm"))
            }
            let idm = idmData.prefix(8).map { String(format: "%02X", $0) }.joined()

            switch self.scanOption.name {
            case "jpIC", "jpIC_SAPICA", "jpIC_IruCa", "jpIC_icsca":
                let blocks = try await reader.readBlocks(
                    service: [0x8B, 0x00], count: 1,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )
                guard let purse = blocks.first, purse.count >= 16 else {
                    throw ReaderError.message(String(localized: "error.smartCardReader.felicaBalance"))
                }
                let historyBlocks = try await reader.readBlocks(
                    service: [0x0F, 0x09],
                    count: min(max(self.scanOption.historyCount, 0), 19),
                    failureKey: "error.smartCardReader.felicaHistoryService",
                    stopAtEmpty: true
                )
                let history = historyBlocks.compactMap(Self.parseSuicaHistory)
                var type = "card.suica"
                var area: String?
                var city: String?
                var issuer: String?
                switch self.scanOption.name {
                case "jpIC_SAPICA":
                    type = "card.SAPICA"
                    area = "locate.prefecture.Hokkaido"
                    city = "issue.jp.hokkaido.city.sapporo"
                    issuer = "issue.jp.hokkaido.issuer.sapporo_information_network"
                case "jpIC_IruCa":
                    type = "card.IruCa"
                    area = "locate.prefecture.Kagawa"
                    city = "issue.jp.kagawa.city.takamatsu"
                    issuer = "issue.jp.kagawa.issuer.kotoden"
                case "jpIC_icsca":
                    type = "card.icsca"
                    area = "locate.prefecture.Miyagi"
                    city = "issue.jp.miyagi.city.sendai"
                    issuer = "issue.jp.miyagi.issuer.sendai_transport"
                default:
                    break
                }
                let info = ResultCardInfo(
                    idm: idm, name: jpIC.name, nameShort: self.scanOption.nameShort,
                    currencyType: self.scanOption.currencyType, type: type,
                    serial: nil, version: nil, validDate: nil,
                    issueInfo: issueInfo(region: jpIC.area.rawValue, area: area, city: city, issuer: issuer)
                )
                return Result(
                    balance: Double(Int(purse[11]) | (Int(purse[12]) << 8)),
                    isHistory: true, history: history, info: info,
                    converter: self.scanOption.converter, isLastHide: true,
                    description: jpIC.scand_description, savedAt: Date.now
                )

            case "hkOctopus":
                let blocks = try await reader.readBlocks(
                    service: [0x17, 0x01], count: 1,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )
                guard let purse = blocks.first, purse.count >= 16 else {
                    throw ReaderError.message(String(localized: "error.smartCardReader.felicaBalance"))
                }
                let raw = purse.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
                let info = ResultCardInfo(
                    idm: idm, name: hkOctopus.name, nameShort: hkOctopus.scanOption.nameShort,
                    currencyType: hkOctopus.scanOption.currencyType, type: "",
                    serial: nil, version: nil, validDate: nil,
                    issueInfo: issueInfo(region: hkOctopus.area.rawValue)
                )
                return Result(
                    balance: Double(max(Int64(raw) - 500, 0)) / 10.0,
                    isHistory: false, history: nil, info: info,
                    converter: hkOctopus.scanOption.converter, isLastHide: false,
                    description: hkOctopus.scand_description, savedAt: Date.now
                )

            case "jpNplus":
                let balanceBlocks = try await reader.readBlocks(
                    service: [0x8B, 0x40], count: 1, start: 1,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )
                guard let balanceData = balanceBlocks.first, balanceData.count >= 7 else {
                    throw ReaderError.message(String(localized: "error.smartCardReader.felicaBalance"))
                }
                let historyBlocks = try await reader.readBlocks(
                    service: [0xCF, 0x80],
                    count: min(max(self.scanOption.historyCount, 0), 20),
                    failureKey: "error.smartCardReader.felicaHistoryService"
                )
                let history = historyBlocks.compactMap(Self.parseNplusHistory)
                let info = ResultCardInfo(
                    idm: idm, name: jpNplus.name, nameShort: jpNplus.scanOption.nameShort,
                    currencyType: jpNplus.scanOption.currencyType, type: "",
                    serial: nil, version: nil, validDate: nil,
                    issueInfo: issueInfo(
                        region: jpNplus.area.rawValue,
                        area: "locate.prefecture.Nagasaki",
                        issuer: "issue.jp.nagasaki.issuer.ntasu"
                    )
                )
                return Result(
                    balance: Double(Int(balanceData[5]) | (Int(balanceData[6]) << 8)),
                    isHistory: true, history: history, info: info,
                    converter: jpNplus.scanOption.converter, isLastHide: true,
                    description: jpNplus.scand_description, savedAt: Date.now
                )

            case "jpOKICA":
                let historyBlocks = try await reader.readBlocks(
                    service: [0x8F, 0x02],
                    count: min(max(self.scanOption.historyCount, 1), 20),
                    failureKey: "error.smartCardReader.felicaHistoryService"
                )
                let history = historyBlocks.compactMap(Self.parseOKICAHistory)
                let info = ResultCardInfo(
                    idm: idm, name: jpOKICA.name, nameShort: jpOKICA.scanOption.nameShort,
                    currencyType: jpOKICA.scanOption.currencyType, type: "",
                    serial: nil, version: nil, validDate: nil,
                    issueInfo: issueInfo(
                        region: jpOKICA.area.rawValue,
                        area: "locate.prefecture.Okinawa",
                        issuer: "issue.jp.okinawa.issuer.okica"
                    )
                )
                return Result(
                    balance: history.first?.balance ?? 0,
                    isHistory: true, history: history, info: info,
                    converter: jpOKICA.scanOption.converter, isLastHide: true,
                    description: jpOKICA.scand_description, savedAt: Date.now
                )

            case "jpDoCard":
                let infoBlocks = try await reader.readBlocks(
                    service: [0x4B, 0x00], count: 1,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )
                guard let infoBlock = infoBlocks.first, infoBlock.count >= 16 else {
                    throw ReaderError.message(String(localized: "error.smartCardReader.felicaBalance"))
                }
                let infoBytes = [UInt8](infoBlock)
                let cardCode = Int(infoBytes[0]) << 8 | Int(infoBytes[1])
                let cardType = cardCode == 0x0102 ? "card.Asaca" : cardCode == 0x0103 ? "card.DoCard" : ""
                let issuer = cardCode == 0x0102
                    ? "issue.jp.hokkaido.issuer.asahikawa_railway"
                    : cardCode == 0x0103 ? "issue.jp.hokkaido.issuer.douhoku_bus" : nil
                let creationRaw = Int(infoBytes[8]) << 8 | Int(infoBytes[9])
                let creationDate = Self.decodeFeliCaDate(creationRaw)
                let balanceHistoryBlocks = try await reader.readBlocks(
                    service: [0x0F, 0x01],
                    count: min(max(self.scanOption.historyCount, 1), 20),
                    failureKey: "error.smartCardReader.felicaHistoryService"
                )
                let history = balanceHistoryBlocks.compactMap {
                    Self.parseDoCardHistory($0, creationDate: creationDate)
                }
                let info = ResultCardInfo(
                    idm: idm, name: jpDoCard.name, nameShort: jpDoCard.scanOption.nameShort,
                    currencyType: jpDoCard.scanOption.currencyType, type: cardType,
                    serial: nil, version: nil, validDate: creationDate.map(Self.formatFeliCaDate),
                    issueInfo: issueInfo(
                        region: jpDoCard.area.rawValue,
                        area: "locate.prefecture.Hokkaido",
                        city: "issue.jp.hokkaido.city.asahikawa",
                        issuer: issuer
                    )
                )
                let cardBalance = balanceHistoryBlocks.first.map {
                    let bytes = [UInt8]($0)
                    return Double(Int(bytes[14]) << 8 | Int(bytes[15]))
                } ?? 0
                return Result(
                    balance: cardBalance,
                    isHistory: true, history: history, info: info,
                    converter: jpDoCard.scanOption.converter, isLastHide: true,
                    description: jpDoCard.scand_description, savedAt: Date.now
                )

            case "jpRapica":
                let attributeBlocks = try await reader.readBlocks(
                    service: [0x4B, 0x00], count: 2,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )
                guard attributeBlocks.count >= 2,
                      attributeBlocks[0].count >= 5,
                      attributeBlocks[1].count >= 8 else {
                    throw ReaderError.message(String(localized: "error.smartCardReader.felicaBalance"))
                }
                let dateBytes = [UInt8](attributeBlocks[0])
                let valueBytes = [UInt8](attributeBlocks[1])
                let referenceDate = DateComponents(
                    year: Int(dateBytes[0]) + 2000,
                    month: Int(dateBytes[1]), day: Int(dateBytes[2]),
                    hour: Int(dateBytes[3]), minute: Int(dateBytes[4])
                )
                let balance = ((Int(valueBytes[4]) << 8) | Int(valueBytes[5]))
                    + ((Int(valueBytes[6]) << 8) | Int(valueBytes[7]))
                let issueBlocks = try await reader.readBlocks(
                    service: [0x0B, 0x00], count: 1,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )
                let issueBytes = issueBlocks.first.map { [UInt8]($0) } ?? []
                let operatorCode = issueBytes.count >= 2
                    ? (Int(issueBytes[0]) << 8 | Int(issueBytes[1])) : 0
                let issuer: String?
                let cardType: String
                switch operatorCode {
                case 0x232F:
                    issuer = "issue.jp.kagoshima.issuer.kagoshimaCity"
                    cardType = "card.rapica"
                case 0x2330:
                    issuer = "issue.jp.kagoshima.issuer.nangoku"
                    cardType = "card.rapica"
                case 0x2332:
                    issuer = "issue.jp.kagoshima.issuer.iwasaki"
                    cardType = "card.iwasaki"
                default:
                    issuer = nil
                    cardType = ""
                }
                var japanCalendar = Calendar(identifier: .gregorian)
                japanCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
                let issueDate: Date? = issueBytes.count >= 8
                    ? japanCalendar.date(from: DateComponents(
                        year: Int(issueBytes[5]) + 2000,
                        month: Int(issueBytes[6]), day: Int(issueBytes[7])
                    )) : nil
                let historyBlocks = try await reader.readBlocks(
                    service: [0x8F, 0x00],
                    count: min(max(self.scanOption.historyCount, 1), 16),
                    failureKey: "error.smartCardReader.felicaHistoryService"
                )
                let history = Self.parseRapicaHistory(historyBlocks, referenceDate: referenceDate)
                let info = ResultCardInfo(
                    idm: idm, name: jpRapica.name, nameShort: jpRapica.scanOption.nameShort,
                    currencyType: jpRapica.scanOption.currencyType,
                    type: cardType,
                    serial: nil, version: nil, validDate: nil,
                    issueInfo: issueInfo(
                        region: jpRapica.area.rawValue,
                        area: "locate.prefecture.Kagoshima", issuer: issuer, date: issueDate
                    )
                )
                return Result(
                    balance: Double(balance), isHistory: true, history: history, info: info,
                    converter: jpRapica.scanOption.converter, isLastHide: true,
                    description: jpRapica.scand_description, savedAt: Date.now
                )

            default:
                throw ReaderError.message(String(localized: "cardList.reader.unsupported"))
            }
        }

        await MainActor.run { self.result = result }
    }

    private static func parseSuicaHistory(_ data: Data) -> ResultHistory? {
        guard data.count >= 16 else { return nil }
        let b = [UInt8](data)
        guard !b.allSatisfy({ $0 == 0 }) else { return nil }
        let rawDate = UInt16(b[4]) << 8 | UInt16(b[5])
        guard rawDate != 0 else { return nil }
        return ResultHistory(
            processType: b[1],
            date: DateComponents(year: Int((rawDate >> 9) & 0x7F) + 2000,
                                 month: Int((rawDate >> 5) & 0x0F), day: Int(rawDate & 0x1F)),
            balance: Double(Int(b[10]) | Int(b[11]) << 8), amount: nil,
            lineIn: b[6], stationIn: b[7], lineOut: b[8], stationOut: b[9],
            transactionId: Int(b[13]) << 8 | Int(b[14])
        )
    }

    private static func parseNplusHistory(_ data: Data) -> ResultHistory? {
        guard data.count >= 16 else { return nil }
        let b = [UInt8](data)
        guard !b.allSatisfy({ $0 == 0 }) else { return nil }
        let rawDate = UInt16(b[0]) << 8 | UInt16(b[1])
        guard rawDate != 0 else { return nil }
        return ResultHistory(
            processType: b[13],
            date: DateComponents(year: Int((rawDate >> 9) & 0x7F) + 2000,
                                 month: Int((rawDate >> 5) & 0x0F), day: Int(rawDate & 0x1F),
                                 hour: Int(b[2]), minute: Int(b[3]), second: Int(b[4])),
            balance: Double(UInt16(b[14]) << 8 | UInt16(b[15])), amount: nil,
            lineIn: 0, stationIn: 0, lineOut: 0, stationOut: 0, transactionId: 0
        )
    }

    private static func parseOKICAHistory(_ data: Data) -> ResultHistory? {
        guard data.count >= 16 else { return nil }
        let b = [UInt8](data)
        guard !b.allSatisfy({ $0 == 0 }) && !b.allSatisfy({ $0 == 0xFF }) else { return nil }
        let rawDate = UInt16(b[4]) << 8 | UInt16(b[5])
        let year = Int((rawDate >> 9) & 0x7F) + 2000
        let month = Int((rawDate >> 5) & 0x0F)
        let day = Int(rawDate & 0x1F)
        guard (1...12).contains(month), (1...31).contains(day) else { return nil }
        return ResultHistory(
            processType: b[1],
            processType4: UInt32(b[0]) << 24 | UInt32(b[1]) << 16 | UInt32(b[2]) << 8 | UInt32(b[3]),
            date: DateComponents(year: year, month: month, day: day),
            balance: Double(Int(b[10]) | Int(b[11]) << 8), amount: nil,
            lineIn: b[6], stationIn: b[7], lineOut: b[8], stationOut: b[9],
            transactionId: Int(b[13]) << 8 | Int(b[14])
        )
    }

    private static func parseDoCardHistory(_ data: Data, creationDate: DateComponents?) -> ResultHistory? {
        guard data.count >= 16 else { return nil }
        let b = [UInt8](data)
        guard !b.allSatisfy({ $0 == 0 }) else { return nil }
        let month = Int(b[0])
        let day = Int(b[1])
        guard (1...12).contains(month), (1...31).contains(day) else { return nil }
        var year = creationDate?.year ?? 0
        if let creationMonth = creationDate?.month, let creationDay = creationDate?.day,
           month < creationMonth || (month == creationMonth && day < creationDay) {
            year += 1
        }
        let processType = b[12]
        let amountOffset = processType == 0x02 ? 9 : 8
        let amount = Double(Int(b[amountOffset]) << 8 | Int(b[amountOffset + 1]))
        return ResultHistory(
            processType: processType,
            date: DateComponents(year: year, month: month, day: day),
            balance: Double(Int(b[14]) << 8 | Int(b[15])), amount: amount,
            lineIn: b[2], stationIn: b[3], lineOut: b[6], stationOut: b[7],
            transactionId: Int(b[11])
        )
    }

    private static func parseRapicaHistory(_ blocks: [Data], referenceDate: DateComponents) -> [ResultHistory] {
        let refYear = referenceDate.year ?? Calendar.current.component(.year, from: Date())
        let refMD = (referenceDate.month ?? 12) * 100 + (referenceDate.day ?? 31)
        let indexed = blocks.enumerated().compactMap { index, data -> (Int, ResultHistory)? in
            let b = [UInt8](data)
            guard b.count >= 16, !b.allSatisfy({ $0 == 0 }), !b.allSatisfy({ $0 == 0xFF }) else { return nil }
            let dateField = Int(b[0]) << 4 | Int(b[1] >> 4)
            let timeField = Int(b[1] & 0x0F) << 8 | Int(b[2])
            let month = dateField / 100
            let day = dateField % 100
            let hour = timeField / 100
            let minute = timeField % 100
            guard (1...12).contains(month), (1...31).contains(day),
                  (0...23).contains(hour), (0...59).contains(minute) else { return nil }
            let year = (month * 100 + day) > refMD ? refYear - 1 : refYear
            let processType = b[12]
            let balance = Double(Int(b[14]) << 8 | Int(b[15]))
            guard !(processType == 0x30 && balance == 0) else { return nil }
            let processType4 = UInt32(b[3]) << 24 | UInt32(b[4]) << 16 | UInt32(b[5]) << 8 | UInt32(b[6])
            let mappingID = String(format: "%04d%02d%02d%02d%02d", year, month, day, hour, minute)
            let history = ResultHistory(
                processType: processType, processType4: processType4,
                date: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute),
                balance: balance, amount: nil, lineIn: 0, stationIn: 0, lineOut: 0, stationOut: 0,
                transactionId: year * 100_000_000 + month * 1_000_000 + day * 10_000 + hour * 100 + minute,
                mappingID: mappingID
            )
            return (index, history)
        }
        return indexed.sorted { lhs, rhs in
            let left = lhs.1.date
            let right = rhs.1.date
            if left.year != right.year { return (left.year ?? 0) > (right.year ?? 0) }
            if left.month != right.month { return (left.month ?? 0) > (right.month ?? 0) }
            if left.day != right.day { return (left.day ?? 0) > (right.day ?? 0) }
            if left.hour != right.hour { return (left.hour ?? 0) > (right.hour ?? 0) }
            if left.minute != right.minute { return (left.minute ?? 0) > (right.minute ?? 0) }
            return lhs.0 < rhs.0
        }.map(\.1)
    }

    private static func decodeFeliCaDate(_ raw: Int) -> DateComponents? {
        guard raw != 0 else { return nil }
        let year = (raw >> 9) + 2000
        let month = (raw >> 5) & 0x0F
        let day = raw & 0x1F
        guard (1...12).contains(month), (1...31).contains(day) else { return nil }
        return DateComponents(year: year, month: month, day: day)
    }

    private static func formatFeliCaDate(_ date: DateComponents) -> String {
        String(format: "%04d/%02d/%02d", date.year ?? 0, date.month ?? 0, date.day ?? 0)
    }
}

private struct FeliCaExternalAPDU {
    let transmit: APDUSend

    func send(_ ins: UInt8, p1: UInt8, p2: UInt8, data: Data = Data(), le: Int = 0) async throws -> Data {
        let (payload, sw1, sw2) = try await transmit(0xFF, ins, p1, p2, data, le)
        guard sw1 == 0x90, sw2 == 0x00 else {
            throw ReaderError.message(String(format: String(localized:
                "error.smartCardReader.felicaCommandFailed"), Int(sw1), Int(sw2)))
        }
        return payload
    }

    func readBlocks(
        service: [UInt8], count: Int, start: Int = 0,
        failureKey: String, stopAtEmpty: Bool = false
    ) async throws -> [Data] {
        // Pass only the service bytes; apduSender supplies Lc for FFA4.
        let (_, sw1, sw2) = try await transmit(
            0xFF, 0xA4, 0x00, 0x01, Data(service), 0
        )
        guard sw1 == 0x90, sw2 == 0x00 else {
            throw ReaderError.message(String(format: String(localized: String.LocalizationValue(failureKey)),
                                             Int(sw1), Int(sw2)))
        }
        var blocks: [Data] = []
        for index in start..<(start + count) {
            let data = try await send(0xB0, p1: 0x00, p2: UInt8(index), le: 256)
            guard data.count >= 16 else {
                throw ReaderError.message(String(localized: "error.smartCardReader.felicaBalance"))
            }
            let block = Data(data.prefix(16))
            if stopAtEmpty && (block.allSatisfy({ $0 == 0 }) || block.allSatisfy({ $0 == 0xFF })) {
                break
            }
            blocks.append(block)
        }
        return blocks
    }
}

extension Data {
    func toIntReversed(_ startIndex: Int, _ endIndex: Int) -> Int {
        var s = 0
        for (n, i) in (startIndex...endIndex).enumerated() {
            s += Int(self[i]) << (n * 8)
        }
        return s
    }
}
