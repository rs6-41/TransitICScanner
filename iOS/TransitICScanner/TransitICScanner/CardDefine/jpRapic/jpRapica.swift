//MARK: かごしま共通乗車カード
import SwiftUI
import Foundation
import CoreNFC

let jpRapica = CardInfo(
    logo: "jpRapica",
    name: "cardList.jpRapica",
    sortName: "cardList.jpRapica.sortName",
    area: .jp,
    countryCode: ["jp"],
    prefectures: ["Kagoshima"],
    regionOption: nil,
    description: "cardList.jpRapica.description",
    scand_description: "jpRapica.scand.description",
    searchWords: ["locate.prefecture.Kagoshima", "かごしま", "カゴシマ", "鹿児島", "kagoshima",
                  "らぴか", "ラピカ", "Rapica", "いわさき", "いわさきICカード",
                  "市電", "市バス", "南国交通", "JR九州バス"],
    scanOption: ScanOption(
        id: .jpRapica,
        nameShort: "jpRapica.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["9481","8194"],
        historyCount: 16,
        currencyType: .jpy,
        converter: .jpRapica,
        scrapingView: nil
    ),
    information: nil,
    sample: ResultSample(
        balance: 1750.0,
        idm: "0102030405060708",
        type: "",
        history: [
            // 降車 (市電 郡元(南)) 残額1750円
            ResultHistory(processType: 0x41, processType4: 0x101E8610, date: sampleDay3, balance: 1750, amount: nil,
                          lineIn: 0, stationIn: 0, lineOut: 0, stationOut: 0, transactionId: 0),
            // 乗車 (市電 武之橋) 残額1910円
            ResultHistory(processType: 0x30, processType4: 0x101E8530, date: sampleDay3, balance: 1910, amount: nil,
                          lineIn: 0, stationIn: 0, lineOut: 0, stationOut: 0, transactionId: 0),
            // 積増 2750円
            ResultHistory(processType: 0x40, processType4: 0x10000000, date: sampleDay2, balance: 2750, amount: nil,
                          lineIn: 0, stationIn: 0, lineOut: 0, stationOut: 0, transactionId: 0),
        ]
    )
)

/// 属性情報(004B)から得られる最新状態
struct RapicaAttribute {
    var balance: Int            // 残額 + プレミア (履歴の残額と同じ基準)
    var lastDate: DateComponents // 直近処理日時
}

extension NFCScannerModel {

    // サービスコードはリトルエンディアンで渡す (例: 008F -> 8F 00)
    private var rapicaService_issue: Data   { Data([0x0B, 0x00]) }
    private var rapicaService_attr: Data    { Data([0x4B, 0x00]) }
    private var rapicaService_history: Data { Data([0x8F, 0x00]) }

    //MARK: スキャン
    func jpRapica_read(_ felicaTag: any FeliCaTagReading) async -> ScanResult? {
        guard let attr = await rapica_attribute(felicaTag) else {
            return nil
        }

        let history = await rapica_history(
            felicaTag,
            count: self.scanOption.historyCount,
            reference: attr.lastDate
        )

        let info = await rapica_info(felicaTag)

        return ScanResult(
            balance: Double(attr.balance),
            isHistory: true,
            history: history,
            info: info,
            converter: jpRapica.scanOption.converter,
            isLastHide: true,
            description: jpRapica.scand_description,
            savedAt: Date.now
        )
    }

    //MARK: 属性情報 (残額・直近処理日時)
    // block0: [0]年 [1]月 [2]日 [3]時 [4]分 (すべてバイナリ)
    // block1: [4-5]残額 [6-7]プレミア (ともにBE)
    func rapica_attribute(_ felicaTag: any FeliCaTagReading) async -> RapicaAttribute? {
        guard let blocks = await rapica_read(felicaTag, service: rapicaService_attr, blockCount: 2),
              blocks.count >= 2 else { return nil }

        let b0 = [UInt8](blocks[0])
        let b1 = [UInt8](blocks[1])
        guard b0.count == 16, b1.count == 16 else { return nil }

        let balance = (Int(b1[4]) << 8 | Int(b1[5]))
        let premium = (Int(b1[6]) << 8 | Int(b1[7]))

        let last = DateComponents(
            year: Int(b0[0]) + 2000,
            month: Int(b0[1]),
            day: Int(b0[2]),
            hour: Int(b0[3]),
            minute: Int(b0[4])
        )

        return RapicaAttribute(balance: balance + premium, lastDate: last)
    }

    //MARK: 履歴
    // 取引番号がないため、mappingIDを日付と取引日時から生成
    //
    func rapica_history(
        _ felicaTag: any FeliCaTagReading,
        count: Int = 16,
        reference: DateComponents
    ) async -> [ResultHistory]? {
        let blockCount = min(max(count, 1), 16)

        guard let blocks = await rapica_read(
            felicaTag,
            service: rapicaService_history,
            blockCount: blockCount
        ) else {
            return nil
        }

        let refYear = reference.year
            ?? Calendar.current.component(.year, from: Date())

        let refMD =
            (reference.month ?? 12) * 100
            + (reference.day ?? 31)

        var parsed: [(key: Int, index: Int, item: ResultHistory)] = []

        for (index, data) in blocks.enumerated() {
            let bytes = [UInt8](data)

            guard bytes.count == 16 else {
                continue
            }

            if bytes.allSatisfy({ $0 == 0x00 })
                || bytes.allSatisfy({ $0 == 0xFF }) {
                continue
            }

            let dateField =
                (Int(bytes[0]) << 4)
                | Int(bytes[1] >> 4)

            let timeField =
                (Int(bytes[1] & 0x0F) << 8)
                | Int(bytes[2])

            let month = dateField / 100
            let day = dateField % 100

            let hour = timeField / 100
            let minute = timeField % 100

            guard
                (1...12).contains(month),
                (1...31).contains(day),
                (0...23).contains(hour),
                (0...59).contains(minute)
            else {
                continue
            }

            let processType = bytes[12]

            let balance = Double(
                Int(bytes[14]) << 8
                | Int(bytes[15])
            )

            let sortYear =
                (month * 100 + day) > refMD
                ? refYear - 1
                : refYear

            // 0円の入場履歴を除外
            if processType == 0x30 && balance == 0 {
                continue
            }

            let operatorAndStop =
                (UInt32(bytes[3]) << 24)
                | (UInt32(bytes[4]) << 16)
                | (UInt32(bytes[5]) << 8)
                | UInt32(bytes[6])

            let date = DateComponents(
                year: sortYear,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )

            // YYYYMMDDHHmm
            let transactionId =
                sortYear * 100_000_000
                + month * 1_000_000
                + day * 10_000
                + hour * 100
                + minute

            let mappingID = String(
                format: "%04d%02d%02d%02d%02d",
                sortYear,
                month,
                day,
                hour,
                minute
            )

            let item = ResultHistory(
                processType: processType,
                processType4: operatorAndStop,
                date: date,
                balance: balance,
                amount: nil,
                lineIn: 0,
                stationIn: 0,
                lineOut: 0,
                stationOut: 0,
                transactionId: transactionId,
                mappingID: mappingID
            )

            let key =
                sortYear * 100_000_000
                + month * 1_000_000
                + day * 10_000
                + hour * 100
                + minute

            parsed.append(
                (
                    key: key,
                    index: index,
                    item: item
                )
            )
        }

        return parsed
            .sorted {
                if $0.key != $1.key {
                    return $0.key > $1.key
                }

                return $0.index < $1.index
            }
            .map {
                $0.item
            }
    }

    //MARK: カード情報
    // 発行情報(000B) block0: [0-1]事業者コード [5-7]発行日(年/月/日) [12-13]デポジット
    func rapica_info(_ felicaTag: any FeliCaTagReading) async -> ResultCardInfo? {

        let idm = felicaTag.currentIDm
            .map { String(format: "%02X", $0) }
            .joined()

        var issueDate: Date? = nil
        var issuerKey:String? = nil
        var type:String = ""

        if let blocks = await rapica_read(felicaTag, service: rapicaService_issue, blockCount: 1),
           let data = blocks.first {
            let b = [UInt8](data)
            if b.count == 16 {
                let operatorCode = (UInt16(b[0]) << 8) | UInt16(b[1])
                switch operatorCode {
                case 0x232F:
                    issuerKey = "issue.jp.kagoshima.issuer.kagoshimaCity"
                    type = "card.rapica"
                case 0x2330:
                    issuerKey = "issue.jp.kagoshima.issuer.nangoku"
                    type = "card.rapica"
                case 0x2332:
                    issuerKey = "issue.jp.kagoshima.issuer.iwasaki"
                    type = "card.iwasaki"
                default: break
                }

                let year = Int(b[5]) + 2000
                let month = Int(b[6])
                let day = Int(b[7])
                if (1...12).contains(month), (1...31).contains(day) {
                    var calendar = Calendar(identifier: .gregorian)
                    calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
                    issueDate = calendar.date(from: DateComponents(year: year, month: month, day: day))
                }
            }
        }

        return ResultCardInfo(
            idm: idm,
            name: jpRapica.name,
            nameShort: jpRapica.scanOption.nameShort,
            currencyType: jpRapica.scanOption.currencyType,
            type: type,
            serial: nil,
            version: nil,
            validDate: nil,
            issueInfo: IssueInfo(
                region: jpRapica.area.rawValue,
                area: "locate.prefecture.Kagoshima",
                issuer: issuerKey,
                date: issueDate
            )
        )
    }

    //MARK: 共通読み取り (8ブロックずつ分割)
    func rapica_read(
        _ tag: any FeliCaTagReading,
        service: Data,
        blockCount: Int,
        blocksPerRead: Int = 8
    ) async -> [Data]? {
        var all: [Data] = []
        var start = 0
        while start < blockCount {
            let end = min(start + blocksPerRead, blockCount)
            guard let chunk = await rapica_readChunk(tag, service: service, range: start..<end) else {
                return nil
            }
            all += chunk
            start = end
        }
        return all
    }

    private func rapica_readChunk(
        _ tag: any FeliCaTagReading,
        service: Data,
        range: Range<Int>
    ) async -> [Data]? {
        await withCheckedContinuation { continuation in
            let blockList = range.map { Data([0x80, UInt8($0)]) }

            tag.readWithoutEncryption(
                serviceCodeList: [service],
                blockList: blockList
            ) { status1, status2, data, error in
                guard error == nil, status1 == 0x00, status2 == 0x00 else {
                    Log.debug("Rapica read error:", status1, status2, error as Any)
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }
}
