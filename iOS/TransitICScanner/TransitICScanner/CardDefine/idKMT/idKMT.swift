import SwiftUI
import Foundation
import CoreNFC

let idKMT = CardInfo(
    logo: "idKMT",
    name: "cardList.idKMT",
    sortName: "cardList.idKMT.sortName",
    area: .id,
    countryCode: ["id"],
    prefectures: ["Jakarta"],
    regionOption: .southEastAsia,
    description: "cardList.idKMT.description",
    scannedDescription: "idKMT.scand.description",
    searchWords: ["KAI", "Commuter", "Kartu Multi Trip", "KMT", "Jakarta", "Indonesia"],
    scanOption: ScanOption(
        id: .idKMT,
        nameShort: "idKMT.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["90B7"],
        historyCount: 20,
        currencyType: .idr,
        converter: .idKMT,
        scrapingView: nil
    ),
    information: nil,
    sample: ResultSample(
        balance: 4000,
        idm: "0127FFFFFFFF6EAB",
        type: "card.KMT",
        history: []
    )
)

extension NFCScannerModel {

    /// KAI Commuter (KMT) を読み取る。内蔵リーダー・外部リーダー共通。
    func idKMTRead(_ felicaTag: any FeliCaTagReading) async -> ScanResult? {
        guard
            let data = await idKMTReadData(
                felicaTag,
                count: self.scanOption.historyCount
            )
        else {
            return nil
        }

        let info = idKMTInfo(felicaTag, data: data)

        return ScanResult(
            balance: Double(data.balance),
            isHistory: true,
            history: data.histories,
            info: info,
            converter: idKMT.scanOption.converter,
            isLastHide: true,
            description: idKMT.scannedDescription,
            savedAt: Date.now
        )
    }

    func idKMTReadData(
        _ felicaTag: any FeliCaTagReading,
        count: Int
    ) async -> KMTData? {
        guard
            let idBlock = await idKMTReadBlocks(
                felicaTag,
                service: Data([0x0B, 0x30]),
                blocks: [0]
            )?.first
        else {
            Log.debug("KMT: ID ブロック(0x300B)を読めませんでした")
            return nil
        }

        guard
            let balanceBlock = await idKMTReadBlocks(
                felicaTag,
                service: Data([0x17, 0x10]),
                blocks: [0]
            )?.first
        else {
            Log.debug("KMT: 残高ブロック(0x1017)を読めませんでした")
            return nil
        }

        let historyBlocks = await idKMTReadHistoryBlocks(
            felicaTag,
            service: Data([0x0F, 0x20]),
            maxCount: min(max(count, 0), 20)
        )

        guard
            let data = KMTData.parse(
                idBlock: idBlock,
                balanceBlock: balanceBlock,
                historyBlocks: historyBlocks
            )
        else {
            // セッションの終了は呼び出し元に任せる（外部リーダーでも共有する）。
            return nil
        }

        return data
    }

    /// 履歴ブロックを先頭から1ブロックずつ読む。
    ///
    /// カードに保存されている履歴の件数より後ろのブロックは読めない（ステータスエラーになる）ため、
    /// まとめて読むと履歴が少ないカードで読取全体が失敗する。
    /// 読めないブロック・空のブロックに達したら、そこまでを履歴として返す。
    func idKMTReadHistoryBlocks(
        _ tag: any FeliCaTagReading,
        service: Data,
        maxCount: Int
    ) async -> [Data] {
        var blocks: [Data] = []

        for index in 0..<min(max(maxCount, 0), 20) {
            guard let block = await idKMTReadBlocks(tag, service: service, blocks: [UInt8(index)])?.first else {
                Log.debug("KMT: 履歴ブロック \(index) 以降は読めないため終了")
                break
            }

            if block.allSatisfy({ $0 == 0 }) || block.allSatisfy({ $0 == 0xFF }) {
                break
            }

            blocks.append(block)
        }

        return blocks
    }

    func idKMTReadBlocks(
        _ tag: any FeliCaTagReading,
        service: Data,
        blocks: [UInt8]
    ) async -> [Data]? {
        guard !blocks.isEmpty else {
            return []
        }

        var result: [Data] = []

        for start in stride(from: 0, to: blocks.count, by: 10) {
            let end = min(start + 10, blocks.count)
            let blockList = blocks[start..<end].map {
                Data([0x80, $0])
            }

            let readResult: [Data]? = await withCheckedContinuation { continuation in
                tag.readWithoutEncryption(
                    serviceCodeList: [service],
                    blockList: blockList
                ) { status1, status2, data, error in
                    guard error == nil,
                        status1 == 0,
                        status2 == 0,
                        data.count == blockList.count,
                        data.allSatisfy({ $0.count == 16 })
                    else {
                        continuation.resume(returning: nil)
                        return
                    }

                    continuation.resume(returning: data)
                }
            }

            guard let readResult else {
                return nil
            }

            result.append(contentsOf: readResult)
        }

        return result
    }

    func idKMTInfo(
        _ felicaTag: any FeliCaTagReading,
        data: KMTData
    ) -> ResultCardInfo {
        let idm = felicaTag.currentIDm
            .map { String(format: "%02X", $0) }
            .joined()

        return ResultCardInfo(
            idm: idm,
            name: idKMT.name,
            nameShort: idKMT.scanOption.nameShort,
            currencyType: idKMT.scanOption.currencyType,
            type: "card.KMT",
            serial: data.serialNumber,
            version: nil,
            validDate: nil,
            issueInfo: IssueInfo(
                region: idKMT.area.rawValue,
                area: "locate.prefecture.Jakarta",
                city: nil,
                issuer: "issue.id.jakarta.issuer.KaiCommuter"
            )
        )
    }
}

struct KMTData {
    let serialNumber: String
    let balance: UInt32
    let lastTransactionAmount: UInt32
    let transactionCounter: UInt32
    let histories: [ResultHistory]

    static func parse(
        idBlock: Data,
        balanceBlock: Data,
        historyBlocks: [Data]
    ) -> KMTData? {
        guard idBlock.count >= 16,
            balanceBlock.count >= 16
        else {
            return nil
        }

        // Data のスライスは開始添字が0とは限らないため、相対位置に正規化する。
        let balanceBlock = Data(Array(balanceBlock))
        let serialBytes = Array(idBlock.prefix(16))

        let serialNumber: String
        if serialBytes.allSatisfy({ $0 >= 0x20 && $0 < 0x7F }) {
            serialNumber = String(
                decoding: serialBytes,
                as: UTF8.self
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            serialNumber =
                serialBytes
                .map { String(format: "%02X", $0) }
                .joined()
        }

        let balance = uint32LittleEndian(balanceBlock, offset: 0)
        let lastTransactionAmount = uint32LittleEndian(balanceBlock, offset: 4)
        let transactionCounter = uint24BigEndian(balanceBlock, offset: 13)

        let histories = historyBlocks.compactMap {
            parseHistory($0)
        }

        return KMTData(
            serialNumber: serialNumber,
            balance: balance,
            lastTransactionAmount: lastTransactionAmount,
            transactionCounter: transactionCounter,
            histories: histories
        )
    }

    private static func parseHistory(_ data: Data) -> ResultHistory? {
        let data = Data(Array(data))
        guard data.count >= 16,
            data[0] != 0
        else {
            return nil
        }

        let gateCode = uint16BigEndian(data, offset: 8)

        guard gateCode != 0 else {
            return nil
        }

        let processType = data[12]
        let sequenceNumber = uint24BigEndian(data, offset: 13)
        let rawAmount = Int64(uint32BigEndian(data, offset: 4))

        let amount: Int64 =
            processType == 1
            ? rawAmount
            : -rawAmount

        let date = parseDate(data)

        let gateHigh = UInt8((gateCode >> 8) & 0xFF)
        let gateLow = UInt8(gateCode & 0xFF)

        let lineIn: UInt8
        let stationIn: UInt8
        let lineOut: UInt8
        let stationOut: UInt8

        if processType == 0 || processType == 2 {
            lineIn = gateHigh
            stationIn = gateLow
            lineOut = 0
            stationOut = 0
        } else {
            lineIn = 0
            stationIn = 0
            lineOut = gateHigh
            stationOut = gateLow
        }

        return ResultHistory(
            processType: processType,
            date: date,
            balance: Double(amount),
            amount: nil,
            lineIn: lineIn,
            stationIn: stationIn,
            lineOut: lineOut,
            stationOut: stationOut,
            transactionId: Int(sequenceNumber)
        )
    }

    private static func parseDate(_ data: Data) -> DateComponents {
        let rawTimestamp = uint32BigEndian(data, offset: 0)
        let epoch2000: TimeInterval = 946_684_800
        let epochTransition: UInt32 = 599_616_000

        let offset: TimeInterval =
            rawTimestamp < epochTransition ? -6 * 60 * 60 : 0

        let date = Date(
            timeIntervalSince1970:
                epoch2000 + TimeInterval(rawTimestamp) + offset
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta")!

        return calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
    }

    private static func uint16BigEndian(
        _ data: Data,
        offset: Int
    ) -> UInt16 {
        (UInt16(data[offset]) << 8)
            | UInt16(data[offset + 1])
    }

    private static func uint24BigEndian(
        _ data: Data,
        offset: Int
    ) -> UInt32 {
        (UInt32(data[offset]) << 16)
            | (UInt32(data[offset + 1]) << 8)
            | UInt32(data[offset + 2])
    }

    private static func uint32BigEndian(
        _ data: Data,
        offset: Int
    ) -> UInt32 {
        (UInt32(data[offset]) << 24)
            | (UInt32(data[offset + 1]) << 16)
            | (UInt32(data[offset + 2]) << 8)
            | UInt32(data[offset + 3])
    }

    private static func uint32LittleEndian(
        _ data: Data,
        offset: Int
    ) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}
