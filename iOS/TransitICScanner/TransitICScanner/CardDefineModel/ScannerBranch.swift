import SwiftUI
import Foundation
import CoreNFC

let cardItems: [CardInfo] = [
    jpIC,
    jpIC_other,
    cnTunion,
    hkOctopus,
    krOneCard
]

/// 種別で動作を切り替える定義
extension NFCScannerModel {
    func switchCard(name:String,_ tag: NFCTag, _ session: NFCTagReaderSession) async {
        switch name {
        case "jpIC":
            self.jpIC_scan(tag,session)
        case "jpIC_other":
            self.jpIC_scan(tag,session)
        case "cnTunion":
            self.cnTunion_scan(tag,session)
        case "hkOctopus":
            await self.hkOctopus_scan(tag,session)
        case "krOneCard":
            await self.hkOctopus_scan(tag,session)
            
        default:
            self.scanError = ScanError(message:String(localized:"scanner.scan.message.undefinedName"))
            return
        }
    }
}

enum ConverterType: String {
    case jpIC
    case jpIC_other
    case cnTunion
    case hkOctopus
    case krOneCard

    func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {
        switch self {
        case .jpIC:
            jpIC_Converter.cardInfo(info)
        case .jpIC_other:
            jpIC_Converter.cardInfo(info)
        case .cnTunion:
            cnTunion_Converter.cardInfo(info)
        case .hkOctopus:
            hkOctopus_Converter.cardInfo(info)
        case .krOneCard:
            krOneCard_Converter.cardInfo(info)
        }
    }

    func history(_ item: ResultHistory) -> DisplayHistory {
        switch self {
        case .jpIC:
            jpIC_Converter.history(item)
        case .jpIC_other:
            jpIC_Converter.history(item)
        case .cnTunion:
            cnTunion_Converter.history(item)
        case .hkOctopus:
            hkOctopus_Converter.history(item)
        case .krOneCard:
            krOneCard_Converter.history(item)
        }
    }
}
