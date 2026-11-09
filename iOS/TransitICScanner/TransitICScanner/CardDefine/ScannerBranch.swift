
import SwiftUI
import Foundation
import Combine
import CoreNFC

final class CardItemsStore: ObservableObject {
    @Published var cardItems: [CardInfo] = []
}

let cardItemsStore = CardItemsStore()

let devCards: [CardInfo] = [
    spFlashPay, idKMT
]

let featureCards: [CardInfo] = []

let relCards: [CardInfo] = [
    jpIC, jpIC_SAPICA, jpIC_IruCa, cnTunion, hkOctopus, krOneCard,
    twICash, jpNplus, jpIC_icsca, twEasyCard_old, jpDoCard, jpOKICA,
    usClipper, jpRapica
]

extension NFCScannerModel {
    func switchCard(name: String, _ tag: NFCTag, _ session: NFCTagReaderSession) async {
        switch name {
        case "jpIC":
            self.jpIC_scan(tag, session)
        case "jpIC_SAPICA":
            self.jpIC_scan(tag, session, optionType: "jpIC_SAPICA")
        case "jpIC_IruCa":
            self.jpIC_scan(tag, session, optionType: "jpIC_IruCa")
        case "cnTunion":
            self.cnTunion_scan(tag, session)
        case "hkOctopus":
            await self.hkOctopus_scan(tag, session)
        case "krOneCard":
            self.krOneCard_scan(tag, session)
        case "twICash":
            self.twICash_scan(tag, session)
        case "jpNplus":
            self.jpNplus_scan(tag, session)
        case "twEasyCard_old":
            return
        case "usClipper":
            self.usClipper_scan(tag, session)
        case "jpDoCard":
            self.jpDoCard_scan(tag, session)
        case "jpIC_icsca":
            self.jpIC_scan(tag, session, optionType: "jpIC_icsca")
        case "jpOKICA":
            self.jpOKICA_scan(tag, session)
        case "jpRapica":
            self.jpRapica_scan(tag, session)
        case "idKMT":
            self.idKMT_scan(tag, session)
        default:
            self.scanError = ScanError(
                message: String(localized: "scanner.scan.message.undefinedName")
            )
            return
        }
    }

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
        case "idKMT":
            try await idKMT_scanExternal(using: manager)
        default:
            throw ReaderError.message(
                String(localized: "cardList.reader.unsupported")
            )
        }
    }

    private func scanFeliCaExternal(using manager: SmartCardManager) async throws {
        let result = try await manager.withCard { card in
            let reader = FeliCaExternalAPDU(
                transmit: manager.apduSender(for: card)
            )

            let idmData = try await reader.send(
                0xCA,
                p1: 0x00,
                p2: 0x00,
                le: 256
            )

            guard idmData.count >= 8 else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaIDm")
                )
            }

            let idm = idmData.prefix(8)
                .map { String(format: "%02X", $0) }
                .joined()

            switch self.scanOption.name {
            case "jpIC", "jpIC_SAPICA", "jpIC_IruCa", "jpIC_icsca":
                let blocks = try await reader.readBlocks(
                    service: [0x8B, 0x00],
                    count: 1,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )

                guard let purse = blocks.first, purse.count >= 16 else {
                    throw ReaderError.message(
                        String(localized: "error.smartCardReader.felicaBalance")
                    )
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
                    idm: idm,
                    name: jpIC.name,
                    nameShort: self.scanOption.nameShort,
                    currencyType: self.scanOption.currencyType,
                    type: type,
                    serial: nil,
                    version: nil,
                    validDate: nil,
                    issueInfo: issueInfo(
                        region: jpIC.area.rawValue,
                        area: area,
                        city: city,
                        issuer: issuer
                    )
                )

                return Result(
                    balance: Double(Int(purse[11]) | (Int(purse[12]) << 8)),
                    isHistory: true,
                    history: history,
                    info: info,
                    converter: self.scanOption.converter,
                    isLastHide: true,
                    description: jpIC.scand_description,
                    savedAt: Date.now
                )

            case "hkOctopus":
                let blocks = try await reader.readBlocks(
                    service: [0x17, 0x01],
                    count: 1,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )

                guard let purse = blocks.first, purse.count >= 16 else {
                    throw ReaderError.message(
                        String(localized: "error.smartCardReader.felicaBalance")
                    )
                }

                let raw = purse.prefix(4).reduce(UInt32(0)) {
                    ($0 << 8) | UInt32($1)
                }

                let info = ResultCardInfo(
                    idm: idm,
                    name: hkOctopus.name,
                    nameShort: hkOctopus.scanOption.nameShort,
                    currencyType: hkOctopus.scanOption.currencyType,
                    type: "",
                    serial: nil,
                    version: nil,
                    validDate: nil,
                    issueInfo: issueInfo(region: hkOctopus.area.rawValue)
                )

                return Result(
                    balance: Double(max(Int64(raw) - 500, 0)) / 10.0,
                    isHistory: false,
                    history: nil,
                    info: info,
                    converter: hkOctopus.scanOption.converter,
                    isLastHide: false,
                    description: hkOctopus.scand_description,
                    savedAt: Date.now
                )

            case "jpNplus":
                let balanceBlocks = try await reader.readBlocks(
                    service: [0x8B, 0x40],
                    count: 1,
                    start: 1,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )

                guard let balanceData = balanceBlocks.first,
                      balanceData.count >= 7 else {
                    throw ReaderError.message(
                        String(localized: "error.smartCardReader.felicaBalance")
                    )
                }

                let historyBlocks = try await reader.readBlocks(
                    service: [0xCF, 0x80],
                    count: min(max(self.scanOption.historyCount, 0), 20),
                    failureKey: "error.smartCardReader.felicaHistoryService"
                )

                let history = historyBlocks.compactMap(Self.parseNplusHistory)

                let info = ResultCardInfo(
                    idm: idm,
                    name: jpNplus.name,
                    nameShort: jpNplus.scanOption.nameShort,
                    currencyType: jpNplus.scanOption.currencyType,
                    type: "",
                    serial: nil,
                    version: nil,
                    validDate: nil,
                    issueInfo: issueInfo(
                        region: jpNplus.area.rawValue,
                        area: "locate.prefecture.Nagasaki",
                        issuer: "issue.jp.nagasaki.issuer.ntasu"
                    )
                )

                return Result(
                    balance: Double(Int(balanceData[5]) | (Int(balanceData[6]) << 8)),
                    isHistory: true,
                    history: history,
                    info: info,
                    converter: jpNplus.scanOption.converter,
                    isLastHide: true,
                    description: jpNplus.scand_description,
                    savedAt: Date.now
                )

            case "jpOKICA":
                let historyBlocks = try await reader.readBlocks(
                    service: [0x8F, 0x02],
                    count: min(max(self.scanOption.historyCount, 1), 20),
                    failureKey: "error.smartCardReader.felicaHistoryService"
                )

                let history = historyBlocks.compactMap(Self.parseOKICAHistory)

                let info = ResultCardInfo(
                    idm: idm,
                    name: jpOKICA.name,
                    nameShort: jpOKICA.scanOption.nameShort,
                    currencyType: jpOKICA.scanOption.currencyType,
                    type: "",
                    serial: nil,
                    version: nil,
                    validDate: nil,
                    issueInfo: issueInfo(
                        region: jpOKICA.area.rawValue,
                        area: "locate.prefecture.Okinawa",
                        issuer: "issue.jp.okinawa.issuer.okica"
                    )
                )

                return Result(
                    balance: history.first?.balance ?? 0,
                    isHistory: true,
                    history: history,
                    info: info,
                    converter: jpOKICA.scanOption.converter,
                    isLastHide: true,
                    description: jpOKICA.scand_description,
                    savedAt: Date.now
                )

            case "jpDoCard":
                let infoBlocks = try await reader.readBlocks(
                    service: [0x4B, 0x00],
                    count: 1,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )

                guard let infoBlock = infoBlocks.first,
                      infoBlock.count >= 16 else {
                    throw ReaderError.message(
                        String(localized: "error.smartCardReader.felicaBalance")
                    )
                }

                let infoBytes = [UInt8](infoBlock)
                let cardCode = Int(infoBytes[0]) << 8 | Int(infoBytes[1])
                let cardType = cardCode == 0x0102
                    ? "card.Asaca"
                    : cardCode == 0x0103 ? "card.DoCard" : ""

                let issuer = cardCode == 0x0102
                    ? "issue.jp.hokkaido.issuer.asahikawa_railway"
                    : cardCode == 0x0103
                        ? "issue.jp.hokkaido.issuer.douhoku_bus"
                        : nil

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
                    idm: idm,
                    name: jpDoCard.name,
                    nameShort: jpDoCard.scanOption.nameShort,
                    currencyType: jpDoCard.scanOption.currencyType,
                    type: cardType,
                    serial: nil,
                    version: nil,
                    validDate: creationDate.map(Self.formatFeliCaDate),
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
                    isHistory: true,
                    history: history,
                    info: info,
                    converter: jpDoCard.scanOption.converter,
                    isLastHide: true,
                    description: jpDoCard.scand_description,
                    savedAt: Date.now
                )

            case "jpRapica":
                let attributeBlocks = try await reader.readBlocks(
                    service: [0x4B, 0x00],
                    count: 2,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )

                guard attributeBlocks.count >= 2,
                      attributeBlocks[0].count >= 5,
                      attributeBlocks[1].count >= 8 else {
                    throw ReaderError.message(
                        String(localized: "error.smartCardReader.felicaBalance")
                    )
                }

                let dateBytes = [UInt8](attributeBlocks[0])
                let valueBytes = [UInt8](attributeBlocks[1])

                let referenceDate = DateComponents(
                    year: Int(dateBytes[0]) + 2000,
                    month: Int(dateBytes[1]),
                    day: Int(dateBytes[2]),
                    hour: Int(dateBytes[3]),
                    minute: Int(dateBytes[4])
                )

                let balance = ((Int(valueBytes[4]) << 8) | Int(valueBytes[5]))
                    + ((Int(valueBytes[6]) << 8) | Int(valueBytes[7]))

                let issueBlocks = try await reader.readBlocks(
                    service: [0x0B, 0x00],
                    count: 1,
                    failureKey: "error.smartCardReader.felicaInfoService"
                )

                let issueBytes = issueBlocks.first.map { [UInt8]($0) } ?? []
                let operatorCode = issueBytes.count >= 2
                    ? (Int(issueBytes[0]) << 8 | Int(issueBytes[1]))
                    : 0

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
                        month: Int(issueBytes[6]),
                        day: Int(issueBytes[7])
                    ))
                    : nil

                let historyBlocks = try await reader.readBlocks(
                    service: [0x8F, 0x00],
                    count: min(max(self.scanOption.historyCount, 1), 16),
                    failureKey: "error.smartCardReader.felicaHistoryService"
                )

                let history = Self.parseRapicaHistory(
                    historyBlocks,
                    referenceDate: referenceDate
                )

                let info = ResultCardInfo(
                    idm: idm,
                    name: jpRapica.name,
                    nameShort: jpRapica.scanOption.nameShort,
                    currencyType: jpRapica.scanOption.currencyType,
                    type: cardType,
                    serial: nil,
                    version: nil,
                    validDate: nil,
                    issueInfo: issueInfo(
                        region: jpRapica.area.rawValue,
                        area: "locate.prefecture.Kagoshima",
                        issuer: issuer,
                        date: issueDate
                    )
                )

                return Result(
                    balance: Double(balance),
                    isHistory: true,
                    history: history,
                    info: info,
                    converter: jpRapica.scanOption.converter,
                    isLastHide: true,
                    description: jpRapica.scand_description,
                    savedAt: Date.now
                )

            default:
                throw ReaderError.message(
                    String(localized: "cardList.reader.unsupported")
                )
            }
        }

        await MainActor.run {
            self.result = result
        }
    }

    private static func parseSuicaHistory(_ data: Data) -> ResultHistory? {
        guard data.count >= 16 else { return nil }

        let b = [UInt8](data)
        guard !b.allSatisfy({ $0 == 0 }) else { return nil }

        let rawDate = UInt16(b[4]) << 8 | UInt16(b[5])
        guard rawDate != 0 else { return nil }

        return ResultHistory(
            processType: b[1],
            date: DateComponents(
                year: Int((rawDate >> 9) & 0x7F) + 2000,
                month: Int((rawDate >> 5) & 0x0F),
                day: Int(rawDate & 0x1F)
            ),
            balance: Double(Int(b[10]) | Int(b[11]) << 8),
            amount: nil,
            lineIn: b[6],
            stationIn: b[7],
            lineOut: b[8],
            stationOut: b[9],
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
            date: DateComponents(
                year: Int((rawDate >> 9) & 0x7F) + 2000,
                month: Int((rawDate >> 5) & 0x0F),
                day: Int(rawDate & 0x1F),
                hour: Int(b[2]),
                minute: Int(b[3]),
                second: Int(b[4])
            ),
            balance: Double(UInt16(b[14]) << 8 | UInt16(b[15])),
            amount: nil,
            lineIn: 0,
            stationIn: 0,
            lineOut: 0,
            stationOut: 0,
            transactionId: 0
        )
    }

    private static func parseOKICAHistory(_ data: Data) -> ResultHistory? {
        guard data.count >= 16 else { return nil }

        let b = [UInt8](data)
        guard !b.allSatisfy({ $0 == 0 }),
              !b.allSatisfy({ $0 == 0xFF }) else {
            return nil
        }

        let rawDate = UInt16(b[4]) << 8 | UInt16(b[5])
        let year = Int((rawDate >> 9) & 0x7F) + 2000
        let month = Int((rawDate >> 5) & 0x0F)
        let day = Int(rawDate & 0x1F)

        guard (1...12).contains(month),
              (1...31).contains(day) else {
            return nil
        }

        return ResultHistory(
            processType: b[1],
            processType4: UInt32(b[0]) << 24
                | UInt32(b[1]) << 16
                | UInt32(b[2]) << 8
                | UInt32(b[3]),
            date: DateComponents(year: year, month: month, day: day),
            balance: Double(Int(b[10]) | Int(b[11]) << 8),
            amount: nil,
            lineIn: b[6],
            stationIn: b[7],
            lineOut: b[8],
            stationOut: b[9],
            transactionId: Int(b[13]) << 8 | Int(b[14])
        )
    }

    private static func parseDoCardHistory(
        _ data: Data,
        creationDate: DateComponents?
    ) -> ResultHistory? {
        guard data.count >= 16 else { return nil }

        let b = [UInt8](data)
        guard !b.allSatisfy({ $0 == 0 }) else { return nil }

        let month = Int(b[0])
        let day = Int(b[1])

        guard (1...12).contains(month),
              (1...31).contains(day) else {
            return nil
        }

        var year = creationDate?.year ?? 0

        if let creationMonth = creationDate?.month,
           let creationDay = creationDate?.day,
           month < creationMonth || (month == creationMonth && day < creationDay) {
            year += 1
        }

        let processType = b[12]
        let amountOffset = processType == 0x02 ? 9 : 8
        let amount = Double(
            Int(b[amountOffset]) << 8 | Int(b[amountOffset + 1])
        )

        return ResultHistory(
            processType: processType,
            date: DateComponents(year: year, month: month, day: day),
            balance: Double(Int(b[14]) << 8 | Int(b[15])),
            amount: amount,
            lineIn: b[2],
            stationIn: b[3],
            lineOut: b[6],
            stationOut: b[7],
            transactionId: Int(b[11])
        )
    }

    private static func parseRapicaHistory(
        _ blocks: [Data],
        referenceDate: DateComponents
    ) -> [ResultHistory] {
        let refYear = referenceDate.year
            ?? Calendar.current.component(.year, from: Date())
        let refMD = (referenceDate.month ?? 12) * 100
            + (referenceDate.day ?? 31)

        let indexed = blocks.enumerated().compactMap {
            index, data -> (Int, ResultHistory)? in

            let b = [UInt8](data)

            guard b.count >= 16,
                  !b.allSatisfy({ $0 == 0 }),
                  !b.allSatisfy({ $0 == 0xFF }) else {
                return nil
            }

            let dateField = Int(b[0]) << 4 | Int(b[1] >> 4)
            let timeField = Int(b[1] & 0x0F) << 8 | Int(b[2])

            let month = dateField / 100
            let day = dateField % 100
            let hour = timeField / 100
            let minute = timeField % 100

            guard (1...12).contains(month),
                  (1...31).contains(day),
                  (0...23).contains(hour),
                  (0...59).contains(minute) else {
                return nil
            }

            let year = (month * 100 + day) > refMD
                ? refYear - 1
                : refYear

            let processType = b[12]
            let balance = Double(Int(b[14]) << 8 | Int(b[15]))

            guard !(processType == 0x30 && balance == 0) else {
                return nil
            }

            let processType4 = UInt32(b[3]) << 24
                | UInt32(b[4]) << 16
                | UInt32(b[5]) << 8
                | UInt32(b[6])

            let mappingID = String(
                format: "%04d%02d%02d%02d%02d",
                year,
                month,
                day,
                hour,
                minute
            )

            let history = ResultHistory(
                processType: processType,
                processType4: processType4,
                date: DateComponents(
                    year: year,
                    month: month,
                    day: day,
                    hour: hour,
                    minute: minute
                ),
                balance: balance,
                amount: nil,
                lineIn: 0,
                stationIn: 0,
                lineOut: 0,
                stationOut: 0,
                transactionId: year * 100_000_000
                    + month * 1_000_000
                    + day * 10_000
                    + hour * 100
                    + minute,
                mappingID: mappingID
            )

            return (index, history)
        }

        return indexed.sorted { lhs, rhs in
            let left = lhs.1.date
            let right = rhs.1.date

            if left.year != right.year {
                return (left.year ?? 0) > (right.year ?? 0)
            }

            if left.month != right.month {
                return (left.month ?? 0) > (right.month ?? 0)
            }

            if left.day != right.day {
                return (left.day ?? 0) > (right.day ?? 0)
            }

            if left.hour != right.hour {
                return (left.hour ?? 0) > (right.hour ?? 0)
            }

            if left.minute != right.minute {
                return (left.minute ?? 0) > (right.minute ?? 0)
            }

            return lhs.0 < rhs.0
        }.map(\.1)
    }

    private static func decodeFeliCaDate(_ raw: Int) -> DateComponents? {
        guard raw != 0 else { return nil }

        let year = (raw >> 9) + 2000
        let month = (raw >> 5) & 0x0F
        let day = raw & 0x1F

        guard (1...12).contains(month),
              (1...31).contains(day) else {
            return nil
        }

        return DateComponents(year: year, month: month, day: day)
    }

    private static func formatFeliCaDate(_ date: DateComponents) -> String {
        String(
            format: "%04d/%02d/%02d",
            date.year ?? 0,
            date.month ?? 0,
            date.day ?? 0
        )
    }
}

private struct FeliCaExternalAPDU {
    let transmit: APDUSend

    func send(
        _ ins: UInt8,
        p1: UInt8,
        p2: UInt8,
        data: Data = Data(),
        le: Int = 0
    ) async throws -> Data {
        let (payload, sw1, sw2) = try await transmit(
            0xFF,
            ins,
            p1,
            p2,
            data,
            le
        )

        guard sw1 == 0x90, sw2 == 0x00 else {
            throw ReaderError.message(
                String(
                    format: String(localized: "error.smartCardReader.felicaCommandFailed"),
                    Int(sw1),
                    Int(sw2)
                )
            )
        }

        return payload
    }

    func readBlocks(
        service: [UInt8],
        count: Int,
        start: Int = 0,
        failureKey: String,
        stopAtEmpty: Bool = false
    ) async throws -> [Data] {
        let (_, sw1, sw2) = try await transmit(
            0xFF,
            0xA4,
            0x00,
            0x01,
            Data(service),
            0
        )

        guard sw1 == 0x90, sw2 == 0x00 else {
            throw ReaderError.message(
                String(
                    format: String(localized: String.LocalizationValue(failureKey)),
                    Int(sw1),
                    Int(sw2)
                )
            )
        }

        var blocks: [Data] = []

        for index in start..<(start + count) {
            let data = try await send(
                0xB0,
                p1: 0x00,
                p2: UInt8(index),
                le: 256
            )

            guard data.count >= 16 else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaBalance")
                )
            }

            let block = Data(data.prefix(16))

            if stopAtEmpty &&
                (block.allSatisfy({ $0 == 0 }) ||
                 block.allSatisfy({ $0 == 0xFF })) {
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

enum ConverterType: String, CaseIterable {
    case jpIC
    case jpIC_SAPICA
    case jpIC_IruCa
    case cnTunion
    case hkOctopus
    case krOneCard
    case twICash
    case jpNplus
    case twEasyCard_old
    case usClipper
    case jpDoCard
    case jpIC_icsca
    case jpOKICA
    case jpRapica
    case idKMT

    func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {
        switch self {
        case .jpIC:
            jpIC_Converter.cardInfo(info)
        case .jpIC_SAPICA:
            jpIC_Converter.cardInfo(info)
        case .jpIC_IruCa:
            jpIC_Converter.cardInfo(info)
        case .cnTunion:
            cnTunion_Converter.cardInfo(info)
        case .hkOctopus:
            hkOctopus_Converter.cardInfo(info)
        case .krOneCard:
            krOneCard_Converter.cardInfo(info)
        case .twICash:
            twICash_Converter.cardInfo(info)
        case .jpNplus:
            jpNplus_Converter.cardInfo(info)
        case .twEasyCard_old:
            twEasyCard_old_Converter.cardInfo(info)
        case .usClipper:
            usClipper_Converter.cardInfo(info)
        case .jpDoCard:
            jpDoCard_Converter.cardInfo(info)
        case .jpIC_icsca:
            jpIC_Converter.cardInfo(info)
        case .jpOKICA:
            jpOKICA_Converter.cardInfo(info)
        case .jpRapica:
            jpRapica_Converter.cardInfo(info)
        case .idKMT:
            idKMT_Converter.cardInfo(info)
        }
    }

    func history(_ item: ResultHistory) -> DisplayHistory {
        switch self {
        case .jpIC:
            jpIC_Converter.history(item)
        case .jpIC_SAPICA:
            jpIC_Converter.history(item)
        case .jpIC_IruCa:
            jpIC_Converter.history(item)
        case .cnTunion:
            cnTunion_Converter.history(item)
        case .hkOctopus:
            hkOctopus_Converter.history(item)
        case .krOneCard:
            krOneCard_Converter.history(item)
        case .twICash:
            twICash_Converter.history(item)
        case .jpNplus:
            jpNplus_Converter.history(item)
        case .twEasyCard_old:
            twEasyCard_old_Converter.history(item)
        case .usClipper:
            usClipper_Converter.history(item)
        case .jpDoCard:
            jpDoCard_Converter.history(item)
        case .jpIC_icsca:
            jpIC_Converter.history(item)
        case .jpOKICA:
            jpOKICA_Converter.history(item)
        case .jpRapica:
            jpRapica_Converter.history(item)
        case .idKMT:
            idKMT_Converter.history(item)
        }
    }
}
