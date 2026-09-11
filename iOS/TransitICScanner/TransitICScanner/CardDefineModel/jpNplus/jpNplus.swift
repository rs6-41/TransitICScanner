import SwiftUI
import Foundation
import CoreNFC

//MARK: エヌタスカード
//交通系IC
let jpNplus = CardInfo(
    logo:"jpNplus",
    name:"cardList.jpNplus",
    area: "cardList.area.jp",
    countryCode: ["jp"],
    description:"cardList.jpNplus.description",
    scand_description: "jpNplus.scand.description",
    searchWords: ["cardList.area.jp"],
    scanOption:ScanOption(
        name:"jpNplus",
        nameShort:"jpNplus.short",
        scanType: .nfc,
        pollingOption:[.iso18092],
        felicaSystemCodes:["93EC"],
        url: nil,
        historyCount:20,
        currency:"currency.jpy",
        converter:.jpNplus
    ),
    infomation: nil
)