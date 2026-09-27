import Foundation
import SwiftUI
import CoreNFC


let usClipper = CardInfo(
    logo: "usClipper",
    name: "cardList.usClipper",
    sortName: "cardList.usClipper.sortName",
    area: .us,
    countryCode: ["us"],
    description: String(localized: "cardList.usClipper.description"),
    scand_description: "",
    searchWords: ["clipper", "sanfrancisco", "bayarea"],
    scanOption: ScanOption(
        name: "usClipper",
        nameShort: "usClipper.short",
        scanType: .nfc,
        pollingOption: [.iso14443],
        felicaSystemCodes: nil,
        historyCount: 20,
        currencyType: .usd,
        converter: .usClipper,
        scrapingView: nil
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance: 25.00,
            idm: "1234567890",
            type: "Clipper",
            history: [
                ResultHistory(
                    processType: 0x01,
                    date: sampleDay2,
                    balance: 25.00,
                    amount: 2.50,
                    lineIn: 0,
                    stationIn: 0,
                    lineOut: 0,
                    stationOut: 0,
                    transactionId: 1
                )
            ]
        )
)

