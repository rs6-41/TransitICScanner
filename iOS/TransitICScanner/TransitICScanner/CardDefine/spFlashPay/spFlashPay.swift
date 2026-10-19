import SwiftUI
import Foundation
import CoreNFC

let spFlashPay = CardInfo(
    logo: "spFlashPay",
    name: "cardList.spFlashPay",
    sortName: "cardList.spFlashPay.sortName",
    area: .sg,
    countryCode: ["sg"],
    prefectures: nil,
    regionOption: nil,
    description: "cardList.spFlashPay.description",
    scand_description: "jpIC.scand.description",
    searchWords: ["card.OKICA","おきか","オキカ","ゆいレール","那覇","琉球"],
    scanOption: ScanOption(
        name: "spFlashPay",
        nameShort: "spFlashPay.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["8FC1"],
        historyCount: 20,
        currencyType: .sgd,
        converter: .jpIC,
        scrapingView: nil
    ),
    infomation: nil,
    sample: ResultSample(
        balance: 1200.0,
        idm: "0405820A9A93CDEF",
        type: "card.OKICA",
        history: [
            ResultHistory(processType: 0x01, processType4: UInt32(0x16010002),date: sampleDay2,balance: 1200,amount: nil,lineIn: 0x00,stationIn: 0x00,lineOut: 0x00,stationOut: 0x00,transactionId: 152
            ),
            ResultHistory(processType: 0x01, processType4: UInt32(0x08020000),date: sampleDay1,balance: 1500,amount: nil,lineIn: 0x00,stationIn: 0x00,lineOut: 0x00,stationOut: 0x00,transactionId: 151
            )
        ]
    )
)
