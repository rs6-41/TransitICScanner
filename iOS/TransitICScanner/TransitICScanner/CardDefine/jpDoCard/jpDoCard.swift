import SwiftUI
import Foundation
import CoreNFC

// MARK: - DoCard

// 未テストのため要テスト

let jpDoCard = CardInfo(
    logo: "jpDoCard",
    name: "cardList.jpDoCard",
    sortName:"cardList.jpDoCard.sortName",
    area: .jp,
    countryCode: ["jp"],
    prefectures: ["Hokkaido"],
    description: "cardList.jpDoCard.description",
    scand_description: "jpDoCard.scand.description",
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
            balance:500.0,
            idm:"0112E09999B35A10",
            type:"card.DoCard",
            history: [
            //TODO: processTypeが適当なため実際の値に修正
            // 2: チャージ 残高1100円 2025/19/23 19:21
            ResultHistory(processType: 0x01,date: sampleDay2,balance: 1100,amount: nil,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 151),
            // 3: 自動改札 残高1099円 2026/1/3 12:58
            ResultHistory(processType: 0x02,date: sampleDay3,balance: 500,amount: nil,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 152),
            ]
        )
)


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

        Task {
            guard let balance = await jpDoCard_balance(felicaTag) else {
                return
            }

            let history = await jpDoCard_history(
                felicaTag,
                count: self.scanOption.historyCount
            )

            let info = await jpDoCard_info(felicaTag)

            await MainActor.run {
                self.result = Result(
                    balance: Double(balance),
                    isHistory: history != nil,
                    history: history,
                    info: info,
                    converter: jpDoCard.scanOption.converter,
                    isLastHide: true,
                    description: jpDoCard.scand_description
                )

                self.session?.alertMessage =
                    String(
                        localized: "scanner.coreNFC.scanning.done"
                    )

                session.invalidate()
            }
        }
    }

    // MARK: - 残高を取得する

    func jpDoCard_balance(
        _ felicaTag: NFCFeliCaTag
    ) async -> Int? {

        guard let data = await jpDoCard_read(
            felicaTag,
            service: Data([0x0F, 0x01]),
            blocks: [0]
        )?.first else {
            return nil
        }

        guard data.count >= 16 else {
            return nil
        }

        let bytes = [UInt8](data)

        let balance =
            (Int(bytes[14]) << 8) |
            Int(bytes[15])

        print(
            "DoCard balance:",
            balance,
            "raw:",
            bytes.map {
                String(format: "%02X", $0)
            }.joined(separator: " ")
        )

        return balance
    }

    // MARK: - 履歴を取得する

    func jpDoCard_history(
        _ felicaTag: NFCFeliCaTag,
        count: Int = 20
    ) async -> [ResultHistory]? {

        let blockCount = min(
            max(count, 1),
            20
        )

        guard let blocks = await jpDoCard_readMultiple(
            felicaTag,
            service: Data([0x0F, 0x01]),
            count: blockCount
        ) else {
            return nil
        }

        let calendar = Calendar(identifier: .gregorian)
        let currentDate = Date()
        let currentYear = calendar.component(
            .year,
            from: currentDate
        )

        let history = blocks.enumerated().compactMap {
            index,
            data -> ResultHistory? in

            guard data.count >= 16 else {
                return nil
            }

            let bytes = [UInt8](data)

            guard !bytes.allSatisfy({ $0 == 0 }) else {
                return nil
            }

            let month = Int(bytes[0])
            let day = Int(bytes[1])

            guard (1...12).contains(month),
                  (1...31).contains(day) else {
                return nil
            }

            let amount = jpDoCard_amount(bytes)

            let balance =
                (Int(bytes[14]) << 8) |
                Int(bytes[15])

            let transactionId = Int(bytes[11])

            let processType = bytes[12]

            let date = jpDoCard_date(
                month: month,
                day: day,
                currentYear: currentYear,
                calendar: calendar
            )

            print(
                String(
                    format: "[%02d] %@",
                    index,
                    bytes.map {
                        String(format: "%02X", $0)
                    }.joined(separator: " ")
                )
            )

            return ResultHistory(
                processType: processType,
                date: date,
                balance: Double(balance),
                amount: amount,
                lineIn: 0,
                stationIn: 0,
                lineOut: 0,
                stationOut: 0,
                transactionId: transactionId
            )
        }

        return history
    }

    // MARK: - DoCard 金額

    private func jpDoCard_amount(
        _ bytes: [UInt8]
    ) -> Double? {

        guard bytes.count >= 11 else {
            return nil
        }

        let amount =
            (Int(bytes[9]) << 8) |
            Int(bytes[10])

        return Double(amount)
    }

    // MARK: - DoCard 日付

    private func jpDoCard_date(
        month: Int,
        day: Int,
        currentYear: Int,
        calendar: Calendar
    ) -> DateComponents {

        var year = currentYear

        if let currentMonth = Calendar.current.dateComponents(
            [.month],
            from: Date()
        ).month {

            if month > currentMonth {
                year -= 1
            }
        }

        return DateComponents(
            year: year,
            month: month,
            day: day
        )
    }

    // MARK: - カード情報

    func jpDoCard_info(
        _ felicaTag: NFCFeliCaTag
    ) async -> ResultCardInfo? {

        let idm = felicaTag.currentIDm
            .map {
                String(format: "%02X", $0)
            }
            .joined()

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

    // MARK: - FeliCa Read Without Encryption

    func jpDoCard_read(
        _ tag: NFCFeliCaTag,
        service: Data,
        blocks: [UInt8]
    ) async -> [Data]? {

        await withCheckedContinuation { continuation in

            let blockList = blocks.map {
                Data([0x80, $0])
            }

            tag.readWithoutEncryption(
                serviceCodeList: [service],
                blockList: blockList
            ) {
                status1,
                status2,
                data,
                error in

                guard error == nil,
                      status1 == 0x00,
                      status2 == 0x00 else {

                    print(
                        "DoCard read error:",
                        error?.localizedDescription ?? "unknown",
                        "status:",
                        String(format: "%02X", status1),
                        String(format: "%02X", status2)
                    )

                    continuation.resume(
                        returning: nil
                    )

                    return
                }

                continuation.resume(
                    returning: data
                )
            }
        }
    }

    // MARK: - 複数Block読み取り

    func jpDoCard_readMultiple(
        _ tag: NFCFeliCaTag,
        service: Data,
        count: Int
    ) async -> [Data]? {

        let blockCount = min(
            max(count, 1),
            20
        )

        return await withCheckedContinuation { continuation in

            let blockList = (0..<blockCount).map {
                Data([0x80, UInt8($0)])
            }

            tag.readWithoutEncryption(
                serviceCodeList: [service],
                blockList: blockList
            ) {
                status1,
                status2,
                data,
                error in

                guard error == nil,
                      status1 == 0x00,
                      status2 == 0x00 else {

                    print(
                        "DoCard history read error:",
                        error?.localizedDescription ?? "unknown",
                        "status:",
                        String(format: "%02X", status1),
                        String(format: "%02X", status2)
                    )

                    continuation.resume(
                        returning: nil
                    )

                    return
                }

                continuation.resume(
                    returning: data
                )
            }
        }
    }
}
