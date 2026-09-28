import SwiftUI
import Foundation
import CoreNFC
import Combine

final class CardItemsStore: ObservableObject {
    @Published var cardItems: [CardInfo] = []
}
let cardItemsStore = CardItemsStore()

// 開発中カード
let devCards: [CardInfo] = [
    usClipper
]

// 試験的な対象カード（「試験的な機能」で有効化）
let featureCards: [CardInfo] = [
    twEasyCard_old
]

// リリース済みのカード
let relCards: [CardInfo] = [
    jpIC,jpIC_SAPICA,jpIC_IruCa,cnTunion,hkOctopus,krOneCard,twICash,jpNplus
]


/// 種別で動作を切り替える定義
extension NFCScannerModel {
    func switchCard(name:String,_ tag: NFCTag, _ session: NFCTagReaderSession) async {
        switch name {
        case "jpIC": self.jpIC_scan(tag,session)
        case "jpIC_SAPICA": self.jpIC_scan(tag,session,optionType: "jpIC_SAPICA")
        case "jpIC_IruCa": self.jpIC_scan(tag,session,optionType: "jpIC_IruCa")
        case "cnTunion": self.cnTunion_scan(tag,session)
        case "hkOctopus": await self.hkOctopus_scan(tag,session)
        case "krOneCard": self.krOneCard_scan(tag,session)
        case "twICash": self.twICash_scan(tag,session)
        case "jpNplus": self.jpNplus_scan(tag,session)
        case "twEasyCard_old": return
        case "usClipper": self.usClipper_scan(tag,session)
            
        default:
            self.scanError = ScanError(message:String(localized:"scanner.scan.message.undefinedName"))
            return
        }
    }
}

enum ConverterType: String,CaseIterable {
    case jpIC
    case jpIC_SAPICA
    case jpIC_IruCa
    case cnTunion
    case hkOctopus
    case krOneCard
    case twICash
    case jpNplus
    case twEasyCard_old
    case usClipper

    func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {
        switch self {
        case .jpIC:
            jpIC_Converter.cardInfo(info)
        case .jpIC_SAPICA:
            jpIC_Converter.cardInfo(info)
        case .jpIC_IruCa:
            jpIC_Converter.cardInfo(info)
        case .cnTunion:
            cnTunion_Converter.cardInfo(info)
        case .hkOctopus:
            hkOctopus_Converter.cardInfo(info)
        case .krOneCard:
            krOneCard_Converter.cardInfo(info)
        case .twICash:
            twICash_Converter.cardInfo(info)
        case .jpNplus:
            jpNplus_Converter.cardInfo(info)
        case .twEasyCard_old:
            twEasyCard_old_Converter.cardInfo(info)
        case .usClipper:
            usClipper_Converter.cardInfo(info)
        }
    }

    func history(_ item: ResultHistory) -> DisplayHistory {
        switch self {
        case .jpIC:
            jpIC_Converter.history(item)
        case .jpIC_SAPICA:
            jpIC_Converter.history(item)
        case .jpIC_IruCa:
            jpIC_Converter.history(item)
        case .cnTunion:
            cnTunion_Converter.history(item)
        case .hkOctopus:
            hkOctopus_Converter.history(item)
        case .krOneCard:
            krOneCard_Converter.history(item)
        case .twICash:
            twICash_Converter.history(item)
        case .jpNplus:
            jpNplus_Converter.history(item)
        case .twEasyCard_old:
            twEasyCard_old_Converter.history(item)
        case .usClipper:
            usClipper_Converter.history(item)
        }
    }
}
