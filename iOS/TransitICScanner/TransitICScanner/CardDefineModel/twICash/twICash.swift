import Foundation
import SwiftUI
import CoreNFC

let twICash = CardInfo(
    logo: "twICash",
    name: "cardList.twICash",
    area: "cardList.area.tw",
    countryCode: ["tw"],
    description:"cardList.twICash.description",
    scand_description: "twICash.scand.description",
    searchWords: ["cardList.area.tw"],
    scanOption: ScanOption(
        name: "twICash",
        nameShort:"twICash.short",
        scanType: .nfc,
        pollingOption: [.iso14443],
        felicaSystemCodes: nil,
        url: nil,
        historyCount: 20,
        currency:  "currency.twd",
        converter: .twICash
    ),
    infomation: nil
)