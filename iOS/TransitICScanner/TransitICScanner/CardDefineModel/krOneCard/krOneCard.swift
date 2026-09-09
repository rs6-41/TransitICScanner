import Foundation
import CoreNFC
import SwiftUI

//MARK: One Card All Pass
//参考：https://github.com/metrodroid/metrodroid/wiki/South-Korea#d4100000030001

let krOneCard = CardInfo(
    logo: "krOneCard_tmoney",
    name: "cardList.krOneCard",
    area: "cardList.area.kr",
    countryCode: ["kr"],
    description: "cardList.krOneCard.description",
    scand_description: "",
    searchWords: ["info.krOneCard.cardName.t-money","info.krOneCard.cardName.ezl","info.krOneCard.cardName.reil_plus","info.krOneCard.cardName.onepass","info.krOneCard.cardName.wowpass","cardList.krOneCard"],
    scanOption: ScanOption(
        name: "krOneCard",
        nameShort: "krOneCard.short",
        scanType: .nfc,
        pollingOption:[.iso14443],
        felicaSystemCodes: nil,
        url: nil,
        historyCount: 20,
        currency: "currency.KRW",
        converter:.krOneCard
    ),
    infomation: AnyView(
        krOneCard_info()
    )
)