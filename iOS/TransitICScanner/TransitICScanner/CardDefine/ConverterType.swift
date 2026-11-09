import Foundation

extension Data {
    func toIntReversed(_ startIndex: Int, _ endIndex: Int) -> Int {
        var s = 0

        for (n, i) in (startIndex...endIndex).enumerated() {
            s += Int(self[i]) << (n * 8)
        }

        return s
    }
}

enum ConverterType: String, CaseIterable {
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
    case jpDoCard
    case jpIC_icsca
    case jpOKICA
    case jpRapica
    case idKMT

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
        case .jpDoCard:
            jpDoCard_Converter.cardInfo(info)
        case .jpIC_icsca:
            jpIC_Converter.cardInfo(info)
        case .jpOKICA:
            jpOKICA_Converter.cardInfo(info)
        case .jpRapica:
            jpRapica_Converter.cardInfo(info)
        case .idKMT:
            idKMT_Converter.cardInfo(info)
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
        case .jpDoCard:
            jpDoCard_Converter.history(item)
        case .jpIC_icsca:
            jpIC_Converter.history(item)
        case .jpOKICA:
            jpOKICA_Converter.history(item)
        case .jpRapica:
            jpRapica_Converter.history(item)
        case .idKMT:
            idKMT_Converter.history(item)
        }
    }
}
