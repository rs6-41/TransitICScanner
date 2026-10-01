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
        name: "jpRapica",
        nameShort: "jpRapica.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["9481","8194"],
        historyCount: 16,
        currencyType: .jpy,
        converter: .jpRapica,
        scrapingView: nil
    ),
    infomation: nil,
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
