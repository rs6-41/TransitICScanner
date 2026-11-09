import SwiftUI
import Foundation
import CoreNFC

let jpDoCard = CardInfo(
    logo: "jpDoCard",
    name: "cardList.jpDoCard",
    sortName: "cardList.jpDoCard.sortName",
    area: .jp,
    countryCode: ["jp"],
    prefectures: ["Hokkaido"],
    regionOption: nil,
    description: "cardList.jpDoCard.description",
    scand_description: "jpIC.scand.description",
    searchWords: ["locate.prefecture.Hokkaido"],
    scanOption: ScanOption(
        id: .jpDoCard,
        nameShort: "jpDoCard.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["8DB6"],
        historyCount: 20,
        currencyType: .jpy,
        converter: .jpDoCard
    ),
    information: nil,
    sample:
        ResultSample(
            balance: 500.0,
            idm: "0112E09999B35A10",
            type: "card.DoCard",
            history: [
                ResultHistory(
                    processType: 0x08,
                    date: sampleDay2,
                    balance: 1100,
                    amount: nil,
                    lineIn: 0x11,
                    stationIn: 0x11,
                    lineOut: 0x11,
                    stationOut: 0x11,
                    transactionId: 151
                ),
                ResultHistory(
                    processType: 0x02,
                    date: sampleDay3,
                    balance: 500,
                    amount: nil,
                    lineIn: 0x11,
                    stationIn: 0x11,
                    lineOut: 0x11,
                    stationOut: 0x11,
                    transactionId: 152
                )
            ]
        )
)

final class JpDoCardFullLog {
    private(set) var text = ""

    func append(_ value: String) {
        text += value + "\n"
    }

    func appendData(_ title: String, _ data: Data) {
        let hex = data
            .map { String(format: "%02X", $0) }
            .joined(separator: " ")

        append("\(title) [\(data.count) bytes]: \(hex)")
    }

    func appendBytes(_ title: String, _ bytes: [UInt8]) {
        let hex = bytes
            .map { String(format: "%02X", $0) }
            .joined(separator: " ")

        append("\(title) [\(bytes.count) bytes]: \(hex)")
    }
}

extension NFCScannerModel {

    func jpDoCard_read(_ felicaTag: any FeliCaTagReading) async -> ScanResult? {
        let fullLog = JpDoCardFullLog()
        let scanDate = Date()

        fullLog.append("===== DOCARD FULL LOG START =====")
        fullLog.append("Scan Date: \(scanDate)")
        fullLog.append("System Code: 8DB6")
        fullLog.appendBytes("IDm", [UInt8](felicaTag.currentIDm))

        let info = await jpDoCard_info(
            felicaTag,
            fullLog: fullLog
        )

        let balance = await jpDoCard_balance(
            felicaTag,
            fullLog: fullLog
        )

        let history = await jpDoCard_history(
            felicaTag,
            count: self.scanOption.historyCount,
            creationDate: info?.validDate,
            fullLog: fullLog
        )

        fullLog.append("===== FINAL RESULT =====")

        if let balance {
            fullLog.append("Balance: \(balance)")
        } else {
            fullLog.append("Balance: unavailable")
        }

        fullLog.append(
            "History Count: \(history?.count ?? 0)"
        )

        fullLog.append(
            "History Available: \(history != nil)"
        )

        if let info {
            fullLog.append("Card Type: \(info.type)")
            fullLog.append(
                "Card Creation Date: \(info.validDate ?? "nil")"
            )
        } else {
            fullLog.append("Card Type: unavailable")
        }

        fullLog.append("===== DOCARD FULL LOG END =====")

        // 残高が読めない場合は 0 円として扱わず読取失敗にする
        guard let balance else {
            return nil
        }

        return ScanResult(
            balance: Double(balance),
            isHistory: history != nil,
            history: history,
            info: info,
            converter: jpDoCard.scanOption.converter,
            isLastHide: true,
            description: jpDoCard.scand_description,
            savedAt: Date.now,
            fullLog: fullLog.text
        )
    }

    func jpDoCard_balance(
        _ felicaTag: any FeliCaTagReading,
        fullLog: JpDoCardFullLog? = nil
    ) async -> Int? {

        fullLog?.append("===== BALANCE READ =====")
        fullLog?.append("System Code: 8DB6")
        fullLog?.append("Service Code: 010F")
        fullLog?.append("Block: 00")

        guard let data = await jpDoCard_read(
            felicaTag,
            service: Data([0x0F, 0x01]),
            blocks: [0],
            fullLog: fullLog
        )?.first else {
            fullLog?.append("Balance read: FAILED")
            return nil
        }

        guard data.count >= 16 else {
            fullLog?.append(
                "Balance read: INVALID DATA LENGTH \(data.count)"
            )
            return nil
        }

        let bytes = [UInt8](data)

        let balance =
            (Int(bytes[14]) << 8) |
            Int(bytes[15])

        fullLog?.appendData(
            "Balance Block 00",
            data
        )

        fullLog?.append(
            String(
                format:
                    "Balance decode: byte[14]=%02X byte[15]=%02X -> %d",
                bytes[14],
                bytes[15],
                balance
            )
        )

        return balance
    }

    func jpDoCard_history(
        _ felicaTag: any FeliCaTagReading,
        count: Int = 20,
        creationDate: String? = nil,
        fullLog: JpDoCardFullLog? = nil
    ) async -> [ResultHistory]? {

        let blockCount = min(
            max(count, 1),
            20
        )

        let creationDateComponents =
            jpDoCard_parseCreationDate(creationDate)

        fullLog?.append("===== HISTORY READ =====")
        fullLog?.append("System Code: 8DB6")
        fullLog?.append("Service Code: 010F")
        fullLog?.append("Requested blocks: \(blockCount)")

        if let creationDateComponents {
            fullLog?.append(
                "Card Creation Date: \(jpDoCard_formatDate(creationDateComponents))"
            )
        }

        var history: [ResultHistory] = []

        for blockIndex in 0..<blockCount {

            fullLog?.append(
                "--- DoCard Block \(blockIndex) ---"
            )

            guard let data = await jpDoCard_read(
                felicaTag,
                service: Data([0x0F, 0x01]),
                blocks: [UInt8(blockIndex)],
                fullLog: fullLog
            )?.first else {
                fullLog?.append(
                    "BLOCK \(blockIndex): READ FAILED"
                )
                break
            }

            guard data.count >= 16 else {
                fullLog?.append(
                    "BLOCK \(blockIndex): INVALID LENGTH \(data.count)"
                )
                break
            }

            let bytes = [UInt8](data)

            fullLog?.appendData(
                "Block \(blockIndex) RAW",
                data
            )

            guard !bytes.allSatisfy({ $0 == 0 }) else {
                fullLog?.append(
                    "BLOCK \(blockIndex): EMPTY"
                )
                continue
            }

            let month = Int(bytes[0])
            let day = Int(bytes[1])

            let dateRaw =
                (Int(bytes[4]) << 8) |
                Int(bytes[5])

            let sequence = Int(bytes[11])
            let processType = bytes[12]

            let balance =
                (Int(bytes[14]) << 8) |
                Int(bytes[15])

            fullLog?.append(
                String(
                    format:
                        "byte[0] Month: %02X (%d)",
                    bytes[0],
                    month
                )
            )

            fullLog?.append(
                String(
                    format:
                        "byte[1] Day: %02X (%d)",
                    bytes[1],
                    day
                )
            )

            fullLog?.append(
                String(
                    format:
                        "byte[4..5] DateRaw: %02X%02X (%d)",
                    bytes[4],
                    bytes[5],
                    dateRaw
                )
            )

            fullLog?.append(
                String(
                    format:
                        "byte[11] Sequence: %02X (%d)",
                    bytes[11],
                    sequence
                )
            )

            fullLog?.append(
                String(
                    format:
                        "byte[12] ProcessType: %02X (%d)",
                    bytes[12],
                    processType
                )
            )

            fullLog?.append(
                String(
                    format:
                        "byte[14..15] Balance: %02X%02X (%d)",
                    bytes[14],
                    bytes[15],
                    balance
                )
            )

            let amount = jpDoCard_amount(
                bytes,
                processType: processType,
                fullLog: fullLog
            )

            let date = jpDoCard_date(
                month: month,
                day: day,
                creationDate: creationDateComponents,
                fullLog: fullLog
            )

            fullLog?.append(
                "Parsed Date: \(jpDoCard_formatDate(date))"
            )

            if let amount {
                fullLog?.append(
                    "Parsed Amount: \(amount)"
                )
            } else {
                fullLog?.append(
                    "Parsed Amount: unavailable"
                )
            }

            fullLog?.append(
                "Parsed Balance: \(balance)"
            )

            fullLog?.append(
                String(
                    format:
                        "Parsed ProcessType: %02X",
                    processType
                )
            )

            let resultHistory = ResultHistory(
                processType: processType,
                date: date,
                balance: Double(balance),
                amount: amount,
                lineIn: bytes[2],
                stationIn: bytes[3],
                lineOut: bytes[6],
                stationOut: bytes[7],
                transactionId: sequence
            )

            history.append(resultHistory)
        }

        fullLog?.append(
            "Parsed history count: \(history.count)"
        )

        return history
    }

    private func jpDoCard_amount(
        _ bytes: [UInt8],
        processType: UInt8,
        fullLog: JpDoCardFullLog? = nil
    ) -> Double? {

        guard bytes.count >= 11 else {
            return nil
        }

        let amount: Int
        let offset: Int

        if processType == 0x02 {
            offset = 9
            amount =
                (Int(bytes[9]) << 8) |
                Int(bytes[10])
        } else {
            offset = 8
            amount =
                (Int(bytes[8]) << 8) |
                Int(bytes[9])
        }

        fullLog?.append(
            String(
                format:
                    "Amount decode source: byte[%d..%d] = %02X %02X -> %d",
                offset,
                offset + 1,
                bytes[offset],
                bytes[offset + 1],
                amount
            )
        )

        return Double(amount)
    }

    private func jpDoCard_date(
        month: Int,
        day: Int,
        creationDate: DateComponents?,
        fullLog: JpDoCardFullLog? = nil
    ) -> DateComponents {

        guard (1...12).contains(month),
              (1...31).contains(day) else {

            fullLog?.append(
                "Date decode: invalid month/day \(month)/\(day)"
            )

            return DateComponents(
                year: 0,
                month: month,
                day: day
            )
        }

        guard let creationYear = creationDate?.year,
              let creationMonth = creationDate?.month,
              let creationDay = creationDate?.day else {

            fullLog?.append(
                "Date decode: creation date unavailable -> year 0"
            )

            return DateComponents(
                year: 0,
                month: month,
                day: day
            )
        }

        var year = creationYear

        if month < creationMonth ||
            (month == creationMonth && day < creationDay) {
            year += 1
        }

        fullLog?.append(
            "Date decode: \(month)/\(day) -> \(year)/\(month)/\(day)"
        )

        return DateComponents(
            year: year,
            month: month,
            day: day
        )
    }

    private func jpDoCard_formatDate(
        _ date: DateComponents
    ) -> String {

        guard let year = date.year,
              let month = date.month,
              let day = date.day else {
            return String(localized: "unknown")
        }

        if year == 0 {
            return "\(month)/\(day)"
        }

        return String(
            format:
                "%04d/%02d/%02d",
            year,
            month,
            day
        )
    }

    private func jpDoCard_parseCreationDate(
        _ value: String?
    ) -> DateComponents? {

        guard let value else {
            return nil
        }

        let parts = value.split(
            separator: "/"
        )

        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }

        return DateComponents(
            year: year,
            month: month,
            day: day
        )
    }

    func jpDoCard_info(
        _ felicaTag: any FeliCaTagReading,
        fullLog: JpDoCardFullLog? = nil
    ) async -> ResultCardInfo? {

        let idm = felicaTag.currentIDm
            .map {
                String(format: "%02X", $0)
            }
            .joined()

        fullLog?.append("===== CARD INFO =====")
        fullLog?.append("IDm: \(idm)")
        fullLog?.append("Card: \(jpDoCard.name)")
        fullLog?.append("===== CARD TYPE DETECTION =====")
        fullLog?.append("Service Code: 004B")
        fullLog?.append("Block: 00")

        guard let data = await jpDoCard_read(
            felicaTag,
            service: Data([0x4B, 0x00]),
            blocks: [0],
            fullLog: fullLog
        )?.first else {

            fullLog?.append(
                "Card type detection: READ FAILED"
            )

            return ResultCardInfo(
                idm: idm,
                name: jpDoCard.name,
                nameShort: jpDoCard.scanOption.nameShort,
                currencyType: jpDoCard.scanOption.currencyType,
                type: "card.DoCard",
                serial: nil,
                version: nil,
                validDate: nil,
                issueInfo: setIssueInfo(nil)
            )
        }

        guard data.count >= 16 else {

            fullLog?.append(
                "Card type detection: INVALID DATA LENGTH \(data.count)"
            )

            return ResultCardInfo(
                idm: idm,
                name: jpDoCard.name,
                nameShort: jpDoCard.scanOption.nameShort,
                currencyType: jpDoCard.scanOption.currencyType,
                type: "card.DoCard",
                serial: nil,
                version: nil,
                validDate: nil,
                issueInfo: setIssueInfo(nil)
            )
        }

        let bytes = [UInt8](data)

        fullLog?.appendData(
            "Card Info Block 00",
            data
        )

        let cardCode =
            (Int(bytes[0]) << 8) |
            Int(bytes[1])

        fullLog?.append(
            String(
                format:
                    "Card Type Code: byte[0..1] = %02X %02X -> 0x%04X (%d)",
                bytes[0],
                bytes[1],
                cardCode,
                cardCode
            )
        )

        let creationDateRaw =
            (Int(bytes[8]) << 8) |
            Int(bytes[9])

        let creationDate =
            jpDoCard_decodeCreationDate(
                creationDateRaw,
                fullLog: fullLog
            )

        let cardType: String
        var issuer:String? = nil

        switch cardCode {
        case 0x0102:
            cardType = "card.Asaca"
            fullLog?.append(
                "Detected Card: Asaca"
            )
            issuer = "issue.jp.hokkaido.issuer.asahikawa_railway"

        case 0x0103:
            cardType = "card.DoCard"
            fullLog?.append(
                "Detected Card: DoCARD"
            )
            issuer = "issue.jp.hokkaido.issuer.douhoku_bus"

        default:
            cardType = ""

            fullLog?.append(
                String(
                    format:
                        "Detected Card: UNKNOWN (0x%04X)",
                    cardCode
                )
            )
        }

        let validDate =
            creationDate.flatMap {
                jpDoCard_formatCreationDate($0)
            }

        fullLog?.append(
            "ResultCardInfo.type: \(cardType)"
        )

        fullLog?.append(
            "ResultCardInfo.validDate: \(validDate ?? "nil")"
        )

        return ResultCardInfo(
            idm: idm,
            name: jpDoCard.name,
            nameShort: jpDoCard.scanOption.nameShort,
            currencyType: jpDoCard.scanOption.currencyType,
            type: cardType,
            serial: nil,
            version: nil,
            validDate: validDate,
            issueInfo: setIssueInfo(issuer)
        )
    }
    
    private func setIssueInfo(_ issuer:String?) -> IssueInfo {
        return IssueInfo(region:jpDoCard.area.rawValue,area:"locate.prefecture.Hokkaido",city:"issue.jp.hokkaido.city.asahikawa",issuer:issuer)
    }

    private func jpDoCard_decodeCreationDate(
        _ value: Int,
        fullLog: JpDoCardFullLog? = nil
    ) -> DateComponents? {

        guard value != 0 else {

            fullLog?.append(
                "Creation Date: 0000 -> unavailable"
            )

            return nil
        }

        let year =
            (value >> 9) + 2000

        let month =
            (value >> 5) & 0x0F

        let day =
            value & 0x1F

        fullLog?.append(
            String(
                format:
                    "Creation Date Raw: %04X",
                value
            )
        )

        fullLog?.append(
            "Creation Date Decode: year=\(year), month=\(month), day=\(day)"
        )

        guard (1...12).contains(month),
              (1...31).contains(day) else {

            fullLog?.append(
                "Creation Date: INVALID"
            )

            return nil
        }

        return DateComponents(
            year: year,
            month: month,
            day: day
        )
    }

    private func jpDoCard_formatCreationDate(
        _ date: DateComponents
    ) -> String? {

        guard let year = date.year,
              let month = date.month,
              let day = date.day,
              year > 0,
              (1...12).contains(month),
              (1...31).contains(day) else {
            return nil
        }

        return String(
            format:
                "%04d/%02d/%02d",
            year,
            month,
            day
        )
    }

    func jpDoCard_read(
        _ tag: any FeliCaTagReading,
        service: Data,
        blocks: [UInt8],
        fullLog: JpDoCardFullLog? = nil
    ) async -> [Data]? {

        let serviceHex = service
            .map {
                String(format: "%02X", $0)
            }
            .joined(separator: " ")

        fullLog?.append(
            "Read Without Encryption"
        )

        fullLog?.append(
            "Service: \(serviceHex)"
        )

        let blockHex = blocks
            .map {
                String(format: "%02X", $0)
            }
            .joined(separator: " ")

        fullLog?.append(
            "Blocks: \(blockHex)"
        )

        let blockList = blocks.map {
            Data([
                0x80,
                $0
            ])
        }

        for (index, block) in blockList.enumerated() {
            fullLog?.appendData(
                "BlockList[\(index)]",
                block
            )
        }

        return await withCheckedContinuation { continuation in

            tag.readWithoutEncryption(
                serviceCodeList: [service],
                blockList: blockList
            ) {
                status1,
                status2,
                data,
                error in

                fullLog?.append(
                    String(
                        format:
                            "Status1: %02X Status2: %02X",
                        status1,
                        status2
                    )
                )

                if let error {
                    fullLog?.append(
                        "Error: \(error.localizedDescription)"
                    )
                } else {
                    fullLog?.append(
                        "Error: nil"
                    )
                }

                fullLog?.append(
                    "Returned blocks: \(data.count)"
                )

                for (index, block) in data.enumerated() {
                    fullLog?.appendData(
                        "Returned Block[\(index)]",
                        block
                    )
                }

                guard error == nil,
                      status1 == 0x00,
                      status2 == 0x00 else {

                    fullLog?.append(
                        "READ RESULT: FAILED"
                    )

                    continuation.resume(
                        returning: nil
                    )

                    return
                }

                fullLog?.append(
                    "READ RESULT: SUCCESS"
                )

                continuation.resume(
                    returning: data
                )
            }
        }
    }
}
