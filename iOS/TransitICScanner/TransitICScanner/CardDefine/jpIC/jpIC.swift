import SwiftUI
import Foundation
import CoreNFC

//MARK: 交通系IC
/// 参考ページ
/// http://jennychan.web.fc2.com/format/suica.html

//交通系IC
let jpIC = CardInfo(
    logo: "jpIC_suica",
    name: "cardList.jpIC",
    sortName: "cardList.jpIC.sortName",
    area: .jp,
    countryCode: ["jp"],
    prefectures: nil,
    regionOption: .eastAsia,
    description: "cardList.jpIC.description",
    scannedDescription: "jpIC.scand.description",
    searchWords: [
        "card.suica", "jpIC_suica", "card.pasmo", "card.icoca", "card.toica", "card.nimoca", "card.manaca", "すいか",
        "ぱすも", "いこか", "といか", "にもか", "まなか", "はやかけん", "info.jpIC.cardName.welcome_suica",
        "info.jpIC.cardName.tourist_pasmo", "cardList.area.jp", "card.company.jr", "じぇーあーる", "にほん", "スイカ", "パスモ", "イコカ",
        "トイカ", "ニモカ", "マナカ", "ハヤカケン", "suika", "pasumo", "ikoka", "toika", "nimoka", "manaka",
    ],
    scanOption: ScanOption(
        id: .jpIC,
        nameShort: "jpIC.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["0003"],
        historyCount: 20,
        currencyType: .jpy,
        converter: .jpIC,
        scrapingView: nil
    ),
    information: nil,
    sample:
        ResultSample(
            balance: 1099.0,
            idm: "0112031212345678",
            type: "card.suica",
            history: [
                // 1: みどりの窓口 新規発行 2025/12/29 10:32
                ResultHistory(
                    processType: 0x19, date: sampleDay1, balance: 1000, amount: nil, lineIn: 0x00, stationIn: 0x00,
                    lineOut: 0x00, stationOut: 0x00, transactionId: 150),
                // 2: 新宿 チャージ 残高1500円 2025/19/23 19:21
                ResultHistory(
                    processType: 0x02, date: sampleDay2, balance: 1500, amount: nil, lineIn: 0x03, stationIn: 0x0D,
                    lineOut: 0x00, stationOut: 0x00, transactionId: 151),
                // 3: 新宿→渋谷 自動改札 残高1099円 2026/1/3 12:58
                ResultHistory(
                    processType: 0x16, date: sampleDay3, balance: 1099, amount: nil, lineIn: 0x03, stationIn: 0x0D,
                    lineOut: 0x25, stationOut: 0x07, transactionId: 152),
            ]
        )
)

//icsca（駅コード以外は共通使用のカード）
let jpIC_icsca = CardInfo(
    logo: "jpIC_icsca",
    name: "cardList.jpIC_icsca",
    sortName: "cardList.jpIC_icsca.sortName",
    area: .jp,
    countryCode: ["jp"],
    prefectures: ["Miyagi"],
    regionOption: nil,
    description: "cardList.jpIC_icsca.description",
    scannedDescription: "jpIC.scand.description",
    searchWords: ["locate.prefecture.Miyagi", "いくすか", "card.icsca", "いくすか", "仙台", "sendai", "せんだい"],
    scanOption: ScanOption(
        id: .jpIC_icsca,
        nameShort: "jpIC_icsca.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["0003"],
        historyCount: 20,
        currencyType: .jpy,
        converter: .jpIC
    ),
    information: nil,
    sample:
        ResultSample(
            balance: 500.0,
            idm: "0112E0D1C4B93A10",
            type: "card.icsca",
            history: [
                //TODO: 駅コード例を調べる（暫定的に全て1111）
                // 2: チャージ 残高1100円 2025/19/23 19:21
                ResultHistory(
                    processType: 0x02, date: sampleDay2, balance: 1100, amount: nil, lineIn: 0x11, stationIn: 0x11,
                    lineOut: 0x11, stationOut: 0x11, transactionId: 151),
                // 3: 自動改札 残高1099円 2026/1/3 12:58
                ResultHistory(
                    processType: 0x16, date: sampleDay3, balance: 500, amount: nil, lineIn: 0x11, stationIn: 0x11,
                    lineOut: 0x11, stationOut: 0x11, transactionId: 152),
            ]
        )
)

//SAPICA（システムコード以外は共通）
let jpIC_SAPICA = CardInfo(
    logo: "jpIC_SAPICA",
    name: "cardList.jpIC_SAPICA",
    sortName: "cardList.jpIC_SAPICA.sortName",
    area: .jp,
    countryCode: ["jp"],
    prefectures: ["Hokkaido"],
    regionOption: nil,
    description: "cardList.jpIC_SAPICA.description",
    scannedDescription: "jpIC.scand.description",
    searchWords: [
        "locate.prefecture.Hokkaido", "jp.sapporo", "さっぽろ", "card.SAPICA", "さぴか", "サッポロ", "サピカ", "sapporo", "hokkaido",
    ],
    scanOption: ScanOption(
        id: .jpIC_SAPICA,
        nameShort: "jpIC_SAPICA.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["865E"],
        historyCount: 20,
        currencyType: .jpy,
        converter: .jpIC
    ),
    information: nil,
    sample:
        ResultSample(
            balance: 500.0,
            idm: "0112E0D1C2B35A10",
            type: "card.SAPICA",
            history: [
                //TODO: 駅コード例を調べる（暫定的に全て1111）
                // 2: チャージ 残高1100円 2025/19/23 19:21
                ResultHistory(
                    processType: 0x02, date: sampleDay2, balance: 1100, amount: nil, lineIn: 0x11, stationIn: 0x11,
                    lineOut: 0x11, stationOut: 0x11, transactionId: 151),
                // 3: 自動改札 残高1099円 2026/1/3 12:58
                ResultHistory(
                    processType: 0x16, date: sampleDay3, balance: 500, amount: nil, lineIn: 0x11, stationIn: 0x11,
                    lineOut: 0x11, stationOut: 0x11, transactionId: 152),
            ]
        )
)

//IruCa（システムコード以外は共通使用のカード）
let jpIC_IruCa = CardInfo(
    logo: "jpIC_iruca",
    name: "cardList.jpIC_IruCa",
    sortName: "cardList.jpIC_IruCa.sortName",
    area: .jp,
    countryCode: ["jp"],
    prefectures: ["Kagawa"],
    regionOption: nil,
    description: "cardList.jpIC_IruCa.description",
    scannedDescription: "jpIC.scand.description",
    searchWords: [
        "locate.prefecture.Kagawa", "かがわ", "card.IruCa", "いるか", "card.company.kotoden", "カガワ", "イルカ", "iruka", "kagawa",
        "ことでん", "高松琴平",
    ],
    scanOption: ScanOption(
        id: .jpIC_IruCa,
        nameShort: "jpIC_IruCa.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["DE80"],
        historyCount: 20,
        currencyType: .jpy,
        converter: .jpIC
    ),
    information: nil,
    sample:
        ResultSample(
            balance: 500.0,
            idm: "0112E1232B35A10",
            type: "card.IruCa",
            history: [
                //TODO: 駅コード例を調べる（暫定的に全て1111）
                // 2: チャージ 残高1100円 2025/19/23 19:21
                ResultHistory(
                    processType: 0x02, date: sampleDay2, balance: 1100, amount: nil, lineIn: 0x11, stationIn: 0x11,
                    lineOut: 0x11, stationOut: 0x11, transactionId: 151),
                // 3: 自動改札 残高1099円 2026/1/3 12:58
                ResultHistory(
                    processType: 0x16, date: sampleDay3, balance: 500, amount: nil, lineIn: 0x11, stationIn: 0x11,
                    lineOut: 0x11, stationOut: 0x11, transactionId: 152),
            ]
        )
)

//カードの読み取り処理
extension NFCScannerModel {

    /// 交通系IC(およびシステムコード違いの互換カード)を読み取る
    func jpIC_read(_ felicaTag: any FeliCaTagReading, cardID: CardID) async -> ScanResult? {
        guard let balance = await jpIC_balance(felicaTag) else { return nil }

        let history = await jpIC_history(
            felicaTag,
            count: self.scanOption.historyCount
        )

        let info = await jpIC_info(felicaTag, cardID: cardID)

        return ScanResult(
            balance: Double(balance),
            isHistory: true,
            history: history,
            info: info,
            converter: jpIC.scanOption.converter,
            isLastHide: true,
            description: jpIC.scannedDescription,
            savedAt: Date.now
        )
    }

    //MARK: 残高を取得する
    func jpIC_balance(_ felicaTag: any FeliCaTagReading) async -> Int? {
        await withCheckedContinuation { continuation in
            let serviceCode = Data([0x00, 0x8B].reversed())
            let blockList = [Data([0x80, 0x00])]

            felicaTag.readWithoutEncryption(serviceCodeList: [serviceCode], blockList: blockList) {
                [weak self] status1, status2, blockData, error in
                if let error = error {
                    Log.debug("Read error: \(error)")
                    self?.session?.invalidate(errorMessage: error.localizedDescription)
                    continuation.resume(returning: nil)
                    return
                }

                guard status1 == 0x00, status2 == 0x00 else {
                    self?.session?.invalidate(
                        errorMessage: String(
                            localized: "scanner.coreNFC.scanning.error.statusFlag,s1:\(status1), s2:\(status2)"))
                    continuation.resume(returning: nil)
                    return
                }

                guard let data = blockData.first else {
                    continuation.resume(returning: nil)
                    return
                }

                let balance = data.toIntReversed(11, 12)
                continuation.resume(returning: Int(balance))
            }
        }
    }

    //MARK: 履歴を取得する
    func jpIC_history(_ felicaTag: any FeliCaTagReading, count: Int = 20) async -> [ResultHistory]? {
        await withCheckedContinuation { continuation in
            let serviceCode = Data([0x0F, 0x09])
            let blockCount = min(max(count, 1), 20)
            let blocksPerRead = 10

            let blockLists = stride(from: 0, to: blockCount, by: blocksPerRead).map { start in
                let end = min(start + blocksPerRead, blockCount)
                return (start..<end).map {
                    Data([0x80, UInt8($0)])
                }
            }

            func readBlocks(_ blockList: [Data], completion: @escaping ([Data]?) -> Void) {
                felicaTag.readWithoutEncryption(
                    serviceCodeList: [serviceCode],
                    blockList: blockList
                ) { status1, status2, blockData, error in
                    Log.debug("History status:", status1, status2, "count:", blockData.count)
                    guard error == nil,
                        status1 == 0x00,
                        status2 == 0x00
                    else {
                        completion(nil)
                        return
                    }

                    completion(blockData)
                }
            }

            func readNext(_ index: Int, result: [Data]) {
                if index >= blockLists.count {
                    for (index, data) in result.enumerated() {
                        let bytes = [UInt8](data)
                        let hex = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                        Log.debug(String(format: "[%02d] %@", index, hex))
                    }
                    let history = result.compactMap { data -> ResultHistory? in
                        let bytes = [UInt8](data)

                        //異常・空データを弾く
                        guard bytes.count == 16 else {
                            return nil
                        }
                        if bytes.allSatisfy({ $0 == 0 }) {
                            return nil
                        }
                        Log.debug("bytes:\(bytes)")

                        //解析
                        let rawDate = UInt16(bytes[4]) << 8 | UInt16(bytes[5])
                        let transactionId =
                            (Int(bytes[13]) << 8) | Int(bytes[14])
                        let balance = Double(Int(bytes[11]) << 8 | Int(bytes[10]))
                        let date = DateComponents(
                            year: Int((rawDate >> 9) & 0x7F) + 2000,
                            month: Int((rawDate >> 5) & 0x0F),
                            day: Int(rawDate & 0x1F)
                        )

                        //空データを弾く
                        if balance == 0 && date.year == 2000 && date.month == 0 && date.day == 0 {
                            return nil
                        }

                        return ResultHistory(
                            processType: bytes[1],
                            date: date,
                            balance: balance,
                            amount: nil,
                            lineIn: bytes[6],
                            stationIn: bytes[7],
                            lineOut: bytes[8],
                            stationOut: bytes[9],
                            transactionId: transactionId
                        )
                    }

                    continuation.resume(returning: history)
                    return
                }

                readBlocks(blockLists[index]) { blockData in
                    guard let blockData else {
                        continuation.resume(returning: nil)
                        return
                    }

                    readNext(index + 1, result: result + blockData)
                }
            }

            readNext(0, result: [])
        }
    }

    //MARK: カード情報を取得する
    func jpIC_info(_ felicaTag: any FeliCaTagReading, cardID: CardID) async -> ResultCardInfo? {

        let idm = felicaTag.currentIDm
            .map { String(format: "%02X", $0) }
            .joined()

        // IDmからのカード種別判定
        let cardIDs: [jpICCheckID] = [
            jpICCheckID(name: "card.suica", maker: ".112", card: "0312", mobile: nil),
            jpICCheckID(name: "card.suica", maker: ".114", card: "0114", mobile: nil),
            jpICCheckID(name: "card.apple", maker: ".139", card: nil, mobile: "E6F5"),
            jpICCheckID(name: "card.phone", maker: ".140", card: nil, mobile: "B660"),
        ]

        var cardType = jpIC_checkCardType(id: idm, lists: cardIDs)
        var issueArea: String?
        var issueCity: String?
        var issuer: String?

        switch cardID {
        case .jpIC_SAPICA:
            cardType = "card.SAPICA"
            issueArea = "locate.prefecture.Hokkaido"
            issueCity = "issue.jp.hokkaido.city.sapporo"
            issuer = "issue.jp.hokkaido.issuer.sapporo_information_network"
        case .jpIC_IruCa:
            cardType = "card.IruCa"
            issueArea = "locate.prefecture.Kagawa"
            issueCity = "issue.jp.kagawa.city.takamatsu"
            issuer = "issue.jp.kagawa.issuer.kotoden"
        case .jpIC_icsca:
            // icsca は宮城県仙台市のカード（city/issuer のキー名は miyazaki だが値は仙台）
            cardType = "card.icsca"
            issueArea = "locate.prefecture.Miyagi"
            issueCity = "issue.jp.miyazaki.city.sendai"
            issuer = "issue.jp.miyazaki.issuer.sendai_transport"
        default: break
        }

        return ResultCardInfo(
            idm: idm,
            name: jpIC.name,
            nameShort: jpIC.scanOption.nameShort,
            currencyType: jpIC.scanOption.currencyType,
            type: cardType,
            serial: nil,
            version: nil,
            validDate: nil,
            issueInfo: IssueInfo(region: jpIC.area.rawValue, area: issueArea, city: issueCity, issuer: issuer)
        )
    }

    func jpIC_checkCardType(id: String, lists: [jpICCheckID]) -> String {
        func wildcardMatch(_ value: String, _ pattern: String) -> Bool {
            guard value.count == pattern.count else { return false }
            return zip(value, pattern).allSatisfy { v, p in
                p == "." || v == p
            }
        }

        let maker = String(id.prefix(4))
        let card = String(id.dropFirst(4).prefix(4))
        let mobile = String(id.suffix(4))

        for list in lists {
            guard wildcardMatch(maker, list.maker) else { continue }

            if let cardPattern = list.card {
                if wildcardMatch(card, cardPattern) {
                    return list.name
                }
            } else if let mobilePattern = list.mobile {
                if wildcardMatch(mobile, mobilePattern) {
                    return list.name
                }
            }
        }

        return ""
    }

    func jpIC_read(
        _ tag: any FeliCaTagReading,
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
            ) { status1, status2, data, error in

                guard error == nil,
                    status1 == 0,
                    status2 == 0
                else {

                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(
                    returning: data
                )
            }
        }
    }

    func jpIC_readMultiple(
        _ tag: any FeliCaTagReading,
        service: Data,
        count: Int
    ) async -> [Data]? {

        await withCheckedContinuation { continuation in

            let blockList = (0..<count).map {
                Data([0x80, UInt8($0)])
            }

            tag.readWithoutEncryption(
                serviceCodeList: [service],
                blockList: blockList
            ) { status1, status2, data, error in

                guard error == nil,
                    status1 == 0x00,
                    status2 == 0x00
                else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: data)
            }
        }
    }
}

struct jpICCheckID {
    let name: String
    let maker: String
    let card: String?
    let mobile: String?
}
