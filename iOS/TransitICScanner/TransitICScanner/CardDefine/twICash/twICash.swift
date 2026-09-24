import Foundation
import SwiftUI
import CoreNFC

let twICash = CardInfo(
    logo: "twICash",
    name: "cardList.twICash",
    sortName:"cardList.twICash.sortName",
    area: .tw,
    countryCode: ["tw"],
    description:String(localized:"cardList.twICash.description"),
    scand_description: "twICash.scand.description",
    searchWords: ["cardList.area.tw","aijinka","ㄞˋㄐㄧㄣㄎㄚˇ"],
    scanOption: ScanOption(
        name: "twICash",
        nameShort:String(localized:"twICash.short"),
        scanType: .nfc,
        pollingOption: [.iso14443],
        felicaSystemCodes: nil,
        historyCount: 20,
        currency:String(localized:"currency.twd"),
        converter: .twICash,
        scrapingView: nil
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance:980.0,
            idm:"7311235747421931",
            type:"",
            history: [
            //TODO: 駅コード例を調べる（暫定的に全て1111）
            // 2: +500TWD 高速鉄道でチャージ 残高1000RMB 2025/19/23 19:21
            ResultHistory(processType: 0x00,date: sampleDay2,balance: 1000,amount: 500,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 151,mappingID: "THR"),
            // 3: 20TWD 台北メトロ改札 残高980RMB 2026/1/3 12:58
            ResultHistory(processType: 0x00,date: sampleDay3,balance: 980,amount: 20,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 152,mappingID: "TRT"),
            ]
        )
)

extension NFCScannerModel {
    func twICash_scan(
        _ tag: NFCTag,
        _ session: NFCTagReaderSession
    ) {
        guard case let .iso7816(isoTag) = tag else {
            session.invalidate(errorMessage: "Not ISO7816 tag")
            return
        }

        Task {
            do {
                let reader = ICash2Reader(tag: isoTag)
                let readResult = try await reader.readCard()

                print("===== iCash 2.0 =====")
                print("Card Number:", readResult.cardNumber)
                print("Balance:", readResult.balance)
                print("Record Count:", readResult.records.count)

                for record in readResult.records {
                    print(
                        "iCash Record:",
                        "date=\(String(describing: record.date))",
                        "mappingID=\(record.mappingID)",
                        "dealer=\(record.dealerName ?? "")",
                        "amount=\(record.amount)",
                        "code=\(String(format: "%02X", record.transactionCode))"
                    )

                    print(
                        "RAW:",
                        record.rawData.map {
                            String(format: "%02X", $0)
                        }.joined(separator: " ")
                    )
                }

                let history = twICash_makeHistory(
                    records: readResult.records,
                    currentBalance: Double(readResult.balance)
                )

                let info = ResultCardInfo(
                    idm: readResult.cardNumber,
                    name: twICash.name,
                    nameShort: twICash.scanOption.nameShort,
                    currency: twICash.scanOption.currency,
                    type: "",
                    serial: readResult.cardNumber,
                    version: nil,
                    validDate: nil
                )

                let balance = Double(readResult.balance)

                await MainActor.run {
                    self.result = Result(
                        balance: balance,
                        isHistory: !history.isEmpty,
                        history: history,
                        info: info,
                        converter: twICash.scanOption.converter,
                        isLastHide: false,
                        description: twICash.scand_description,
                        savedAt: Date.now
                    )

                    session.invalidate()
                }
            } catch {
                print(
                    "iCash 2.0 scan error:",
                    error.localizedDescription
                )

                await MainActor.run {
                    session.invalidate(
                        errorMessage: error.localizedDescription
                    )
                }
            }
        }
    }

    private func twICash_makeHistory(
        records: [ICash2Record],
        currentBalance: Double
    ) -> [ResultHistory] {
        let sortedRecords = records.sorted {
            let lhsDate = $0.date ?? Date.distantPast
            let rhsDate = $1.date ?? Date.distantPast

            if lhsDate != rhsDate {
                return lhsDate > rhsDate
            }

            return twICash_transactionID(
                record: $0
            ) > twICash_transactionID(
                record: $1
            )
        }

        var currentHistoricalBalance = currentBalance
        var history: [ResultHistory] = []

        for record in sortedRecords {
            let balance = currentHistoricalBalance

            let historyItem = ResultHistory(
                processType: record.transactionCode,
                date: twICash_dateComponents(
                    from: record.date
                ),
                balance: balance,
                amount: record.amount == 0
                    ? nil
                    : Double(record.amount),
                lineIn: 0,
                stationIn: 0,
                lineOut: 0,
                stationOut: 0,
                transactionId: twICash_transactionID(
                    record: record
                ),
                mappingID: record.mappingID
            )

            history.append(historyItem)

            currentHistoricalBalance -= Double(record.amount)
        }

        return history
    }

    private func twICash_dateComponents(
        from date: Date?
    ) -> DateComponents {
        guard let date else {
            return DateComponents()
        }

        var calendar = Calendar(
            identifier: .gregorian
        )

        guard let timeZone = TimeZone(
            identifier: "Asia/Taipei"
        ) else {
            return DateComponents()
        }

        calendar.timeZone = timeZone

        return calendar.dateComponents(
            [
                .year,
                .month,
                .day,
                .hour,
                .minute,
                .second
            ],
            from: date
        )
    }

    private func twICash_transactionID(
        record: ICash2Record
    ) -> Int {
        var value = 0

        for byte in record.rawData.prefix(4) {
            value = (value << 8) | Int(byte)
        }

        return value
    }
}

struct ICash2Record {
    let date: Date?
    let mappingID: String
    let dealerName: String?
    let amount: Int64
    let transactionCode: UInt8
    let rawData: Data
}

struct ICash2ReadResult {
    let cardNumber: String
    let balance: Int32
    let records: [ICash2Record]
}

enum ICash2ReaderError: LocalizedError {
    case invalidResponse
    case unexpectedStatus(UInt8, UInt8)
    case invalidLength
    case invalidRecordLength
    case invalidData
    case communicationError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "NFCレスポンスが不正です。"

        case .unexpectedStatus(let sw1, let sw2):
            return String(
                format: "カードからエラーが返されました: %02X %02X",
                sw1,
                sw2
            )

        case .invalidLength:
            return "カードから返されたデータ長が不正です。"

        case .invalidRecordLength:
            return "取引履歴のデータ長が不正です。"

        case .invalidData:
            return "カードデータが不正です。"

        case .communicationError(let error):
            return "NFC通信エラー: \(error.localizedDescription)"
        }
    }
}

final class ICash2Reader {
    private weak var tag: NFCISO7816Tag?

    init(tag: NFCISO7816Tag) {
        self.tag = tag
    }

    func readCard() async throws -> ICash2ReadResult {
        try await selectAID()

        let cardNumberData = try await readDataFreeKey(
            file: 3,
            length: 8
        )

        let cardNumber = cardNumberData.hexString

        let balanceData = try await getValueFreeKey(
            file: 6
        )

        guard balanceData.count == 4 else {
            throw ICash2ReaderError.invalidLength
        }

        let balance =
            Int32(balanceData[0]) |
            (Int32(balanceData[1]) << 8) |
            (Int32(balanceData[2]) << 16) |
            (Int32(balanceData[3]) << 24)

        let recordsData = try await readRecentRecords()
        let records = parseRecentRecords(recordsData)

        return ICash2ReadResult(
            cardNumber: cardNumber,
            balance: balance,
            records: records
        )
    }

    private func selectAID() async throws {
        let response = try await transmit(
            instructionClass: 0x90,
            instructionCode: 0x5A,
            p1: 0x00,
            p2: 0x00,
            data: Data([
                0x11,
                0x87,
                0x16
            ]),
            expectedResponseLength: 256
        )

        try checkStatus(response)
    }

    private func readDataFreeKey(
        file: UInt8,
        length: UInt8
    ) async throws -> Data {
        let data = Data([
            file,
            0x00,
            0x00,
            0x00,
            length,
            0x00,
            0x00
        ])

        let response = try await transmit(
            instructionClass: 0x90,
            instructionCode: 0xBD,
            p1: 0x00,
            p2: 0x00,
            data: data,
            expectedResponseLength: 256
        )

        try checkStatus(response)

        guard response.data.count == Int(length) else {
            throw ICash2ReaderError.invalidLength
        }

        return response.data
    }

    private func getValueFreeKey(
        file: UInt8
    ) async throws -> Data {
        let data = Data([
            file
        ])

        let response = try await transmit(
            instructionClass: 0x90,
            instructionCode: 0x6C,
            p1: 0x00,
            p2: 0x00,
            data: data,
            expectedResponseLength: 256
        )

        try checkStatus(response)

        guard response.data.count == 4 else {
            throw ICash2ReaderError.invalidLength
        }

        return response.data
    }

    private func readRecentRecords() async throws -> Data {
        let data = Data([
            0x0D,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00
        ])

        var response = try await transmit(
            instructionClass: 0x90,
            instructionCode: 0xBB,
            p1: 0x00,
            p2: 0x00,
            data: data,
            expectedResponseLength: 256
        )

        var result = Data()
        result.append(response.data)

        while response.statusWord1 == 0x91 &&
              response.statusWord2 == 0xAF {
            response = try await transmit(
                instructionClass: 0x90,
                instructionCode: 0xAF,
                p1: 0x00,
                p2: 0x00,
                data: Data(),
                expectedResponseLength: 256
            )

            result.append(response.data)
        }

        guard response.statusWord1 == 0x91 &&
              response.statusWord2 == 0x00 else {
            throw ICash2ReaderError.unexpectedStatus(
                response.statusWord1,
                response.statusWord2
            )
        }

        guard result.count % 51 == 0 else {
            throw ICash2ReaderError.invalidRecordLength
        }

        return result
    }

    private struct Response {
        let data: Data
        let statusWord1: UInt8
        let statusWord2: UInt8
    }

    private func transmit(
        instructionClass: UInt8,
        instructionCode: UInt8,
        p1: UInt8,
        p2: UInt8,
        data: Data,
        expectedResponseLength: Int
    ) async throws -> Response {
        guard let tag else {
            throw ICash2ReaderError.invalidData
        }

        let apdu = NFCISO7816APDU(
            instructionClass: instructionClass,
            instructionCode: instructionCode,
            p1Parameter: p1,
            p2Parameter: p2,
            data: data,
            expectedResponseLength: expectedResponseLength
        )

        let response: Data

        do {
            response = try await withCheckedThrowingContinuation {
                continuation in

                tag.sendCommand(apdu: apdu) {
                    data,
                    sw1,
                    sw2,
                    error in

                    if let error {
                        continuation.resume(
                            throwing:
                                ICash2ReaderError.communicationError(
                                    error
                                )
                        )
                        return
                    }

                    var result = Data(data)
                    result.append(sw1)
                    result.append(sw2)

                    continuation.resume(
                        returning: result
                    )
                }
            }
        } catch let error as ICash2ReaderError {
            throw error
        } catch {
            throw ICash2ReaderError.communicationError(error)
        }

        guard response.count >= 2 else {
            throw ICash2ReaderError.invalidResponse
        }

        let sw1 = response[response.count - 2]
        let sw2 = response[response.count - 1]

        let body = Data(
            response.dropLast(2)
        )

        return Response(
            data: body,
            statusWord1: sw1,
            statusWord2: sw2
        )
    }

    private func checkStatus(
        _ response: Response
    ) throws {
        guard response.statusWord1 == 0x91 &&
              response.statusWord2 == 0x00 else {
            throw ICash2ReaderError.unexpectedStatus(
                response.statusWord1,
                response.statusWord2
            )
        }
    }

    private func parseRecentRecords(
        _ data: Data
    ) -> [ICash2Record] {
        guard data.count % 51 == 0 else {
            return []
        }

        let recordCount = data.count / 51
        var records: [ICash2Record] = []

        guard recordCount > 0 else {
            return records
        }

        for index in stride(
            from: recordCount - 1,
            through: 0,
            by: -1
        ) {
            let start = index * 51
            let end = start + 51

            let recordData = Data(
                data[start..<end]
            )

            let date = parseRecordDate(recordData)

            let mappingID = String(
                bytes: [
                    recordData[19],
                    recordData[20],
                    recordData[21]
                ],
                encoding: .ascii
            ) ?? ""

            let dealerBytes = Data(
                recordData[22...32]
            )

            let dealerName = String(
                data: dealerBytes,
                encoding: .ascii
            )?
            .trimmingCharacters(
                in: .controlCharacters
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            let transactionCode = recordData[38]

            let rawAmount = parseAmount(
                recordData[43],
                recordData[44],
                recordData[45],
                recordData[46]
            )

            let amount: Int64

            if rawAmount == 0 {
                amount = 0
            } else if isNegativeTransaction(
                transactionCode
            ) {
                amount = -rawAmount
            } else {
                amount = rawAmount
            }

            records.append(
                ICash2Record(
                    date: date,
                    mappingID: mappingID,
                    dealerName: dealerName,
                    amount: amount,
                    transactionCode: transactionCode,
                    rawData: recordData
                )
            )
        }

        return records
    }

    private func parseRecordDate(
        _ recordData: Data
    ) -> Date? {
        guard recordData.count >= 11 else {
            return nil
        }

        let year = decimalValueFromHexBytes(
            recordData[4],
            recordData[5]
        )

        let month = decimalValueFromHexBytes(
            recordData[6]
        )

        let day = decimalValueFromHexBytes(
            recordData[7]
        )

        let hour = decimalValueFromHexBytes(
            recordData[8]
        )

        let minute = decimalValueFromHexBytes(
            recordData[9]
        )

        let second = decimalValueFromHexBytes(
            recordData[10]
        )

        guard year >= 1,
              month >= 1,
              month <= 12,
              day >= 1,
              day <= 31,
              hour >= 0,
              hour <= 23,
              minute >= 0,
              minute <= 59,
              second >= 0,
              second <= 59 else {
            return nil
        }

        var calendar = Calendar(
            identifier: .gregorian
        )

        guard let timeZone = TimeZone(
            identifier: "Asia/Taipei"
        ) else {
            return nil
        }

        calendar.timeZone = timeZone

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second

        return calendar.date(
            from: components
        )
    }

    private func parseAmount(
        _ byte0: UInt8,
        _ byte1: UInt8,
        _ byte2: UInt8,
        _ byte3: UInt8
    ) -> Int64 {
        let hexString = String(
            format: "%02X%02X%02X%02X",
            byte0,
            byte1,
            byte2,
            byte3
        )

        return Int64(hexString) ?? 0
    }

    private func decimalValueFromHexBytes(
        _ bytes: UInt8...
    ) -> Int {
        let hexString = bytes
            .map {
                String(
                    format: "%02X",
                    $0
                )
            }
            .joined()

        return Int(hexString) ?? 0
    }

    private func isNegativeTransaction(
        _ transactionCode: UInt8
    ) -> Bool {
        switch transactionCode {
        case 0x00...0x15:
            return true
        case 0x48:
            return true
        case 0x49:
            return true
        case 0x51:
            return true
        case 0x54:
            return true
        default:
            return false
        }
    }
}

private extension Data {
    var hexString: String {
        map {
            String(
                format: "%02X",
                $0
            )
        }
        .joined()
    }
}
