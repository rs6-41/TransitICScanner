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
        name: "jpDoCard",
        nameShort: "jpDoCard.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["8DB6"],
        historyCount: 20,
        currencyType: .jpy,
        converter: .jpDoCard
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance: 500.0,
            idm: "0112E09999B35A10",
            type: "card.DoCard",
            history: [
                ResultHistory(
                    processType: 0x01,
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
        text += value
        text += "\n"
    }

    func appendData(_ title: String, _ data: Data) {
        let hex = data
            .map {
                String(format: "%02X", $0)
            }
            .joined(separator: " ")

        append(
            "\(title) [\(data.count) bytes]: \(hex)"
        )
    }

    func appendBytes(_ title: String, _ bytes: [UInt8]) {
        let hex = bytes
            .map {
                String(format: "%02X", $0)
            }
            .joined(separator: " ")

        append(
            "\(title) [\(bytes.count) bytes]: \(hex)"
        )
    }
}

extension NFCScannerModel {

    func jpDoCard_scan(
        _ tag: NFCTag,
        _ session: NFCTagReaderSession
    ) {
        guard case let .feliCa(felicaTag) = tag else {
            session.invalidate(
                errorMessage: String(
                    localized: "scanner.coreNFC.error.notfeliCa"
                )
            )
            return
        }

        let fullLog = JpDoCardFullLog()

        let scanDate = Date()

        let idm = felicaTag.currentIDm
            .map {
                String(format: "%02X", $0)
            }
            .joined()

        fullLog.append(
            "===== DOCARD FULL LOG START ====="
        )

        fullLog.append(
            "Scan Date: \(scanDate)"
        )

        fullLog.append(
            "System Code: 8DB6"
        )

        fullLog.appendBytes(
            "IDm",
            [UInt8](felicaTag.currentIDm)
        )

        Task { @MainActor [self] in

            guard let balance = await jpDoCard_balance(
                felicaTag,
                fullLog: fullLog
            ) else {

                fullLog.append(
                    "===== FINAL RESULT ====="
                )

                fullLog.append(
                    "Balance: unavailable"
                )

                fullLog.append(
                    "History Available: false"
                )

                fullLog.append(
                    "===== DOCARD FULL LOG END ====="
                )

                self.result = Result(
                    balance: 0,
                    isHistory: false,
                    history: nil,
                    info: await jpDoCard_info(
                        felicaTag,
                        fullLog: fullLog
                    ),
                    converter: jpDoCard.scanOption.converter,
                    isLastHide: true,
                    description: jpDoCard.scand_description,
                    savedAt: Date.now,
                    fullLog: fullLog.text
                )

                self.session?.alertMessage =
                    String(
                        localized: "scanner.coreNFC.scanning.done"
                    )

                session.invalidate()
                return
            }

            let history = await jpDoCard_history(
                felicaTag,
                count: self.scanOption.historyCount,
                fullLog: fullLog
            )

            let info = await jpDoCard_info(
                felicaTag,
                fullLog: fullLog
            )

            fullLog.append(
                "===== FINAL RESULT ====="
            )

            fullLog.append(
                "Balance: \(balance)"
            )

            fullLog.append(
                "History Count: \(history?.count ?? 0)"
            )

            fullLog.append(
                "History Available: \(history != nil)"
            )

            fullLog.append(
                "===== DOCARD FULL LOG END ====="
            )

            self.result = Result(
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

            self.session?.alertMessage =
                String(
                    localized: "scanner.coreNFC.scanning.done"
                )

            session.invalidate()
        }
    }

    func jpDoCard_balance(
        _ felicaTag: NFCFeliCaTag,
        fullLog: JpDoCardFullLog? = nil
    ) async -> Int? {

        fullLog?.append(
            "===== BALANCE READ ====="
        )

        fullLog?.append(
            "Service Code: 010F"
        )

        fullLog?.append(
            "Block: 00"
        )

        guard let data = await jpDoCard_read(
            felicaTag,
            service: Data([0x0F, 0x01]),
            blocks: [0],
            fullLog: fullLog
        )?.first else {

            fullLog?.append(
                "Balance read: FAILED"
            )

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
        _ felicaTag: NFCFeliCaTag,
        count: Int = 20,
        fullLog: JpDoCardFullLog? = nil
    ) async -> [ResultHistory]? {

        let blockCount = min(
            max(count, 1),
            20
        )

        fullLog?.append(
            "===== HISTORY READ ====="
        )

        fullLog?.append(
            "Service Code: 010F"
        )

        fullLog?.append(
            "Requested blocks: \(blockCount)"
        )

        let calendar = Calendar(identifier: .gregorian)
        let currentDate = Date()

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
                dateRaw: dateRaw,
                currentDate: currentDate,
                calendar: calendar,
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
                String(
                    format:
                        "Parsed Balance: %d",
                    balance
                )
            )

            fullLog?.append(
                String(
                    format:
                        "Parsed ProcessType: %02X",
                    processType
                )
            )

            fullLog?.append(
                String("Parsed ConsoleType byte[2]: (\(String(bytes[2])))")
            )

            let resultHistory = ResultHistory(
                processType: UInt8(Int(processType)),
                date: date,
                balance: Double(balance),
                amount: amount,
                lineIn: UInt8(Int(bytes[2])),
                stationIn: UInt8(Int(bytes[3])),
                lineOut: UInt8(Int(bytes[6])),
                stationOut: UInt8(Int(bytes[7])),
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
        dateRaw: Int,
        currentDate: Date,
        calendar: Calendar,
        fullLog: JpDoCardFullLog? = nil
    ) -> DateComponents {

        fullLog?.append(
            String(
                format: "Date decode: DateRaw = %04X",
                dateRaw
            )
        )

        fullLog?.append(
            "Date year: unknown -> 0"
        )

        return DateComponents(
            year: 0,
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

        return "\(year)/\(month)/\(day)"
    }

    func jpDoCard_info(
        _ felicaTag: NFCFeliCaTag,
        fullLog: JpDoCardFullLog? = nil
    ) async -> ResultCardInfo? {

        let idm = felicaTag.currentIDm
            .map {
                String(format: "%02X", $0)
            }
            .joined()

        fullLog?.append(
            "===== CARD INFO ====="
        )

        fullLog?.append(
            "IDm: \(idm)"
        )

        fullLog?.append(
            "Card: \(jpDoCard.name)"
        )

        return ResultCardInfo(
            idm: idm,
            name: jpDoCard.name,
            nameShort: jpDoCard.scanOption.nameShort,
            currencyType: jpDoCard.scanOption.currencyType,
            type: jpDoCard.name,
            serial: nil,
            version: nil,
            validDate: nil
        )
    }

    func jpDoCard_read(
        _ tag: NFCFeliCaTag,
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
