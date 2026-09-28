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
        converter: .jpIC
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance:500.0,
            idm:"0112E0D1C2B35A10",
            type:"card.DoCard",
            history: [
            //TODO: 駅コード例を調べる（暫定的に全て1111）
            // 2: チャージ 残高1100円 2025/19/23 19:21
            ResultHistory(processType: 0x02,date: sampleDay2,balance: 1100,amount: nil,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 151),
            // 3: 自動改札 残高1099円 2026/1/3 12:58
            ResultHistory(processType: 0x16,date: sampleDay3,balance: 500,amount: nil,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 152),
            ]
        )
)
