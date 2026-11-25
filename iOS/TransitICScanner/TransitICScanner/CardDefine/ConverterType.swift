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

nonisolated enum ConverterType: String, CaseIterable {
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
    case idKAI
    case spEZLink

    init?(rawValue: String) {
        let identifier = CardIdentity.canonicalID(rawValue)
        guard let value = Self.allCases.first(where: { $0.rawValue == identifier }) else {
            return nil
        }
        self = value
    }

    @MainActor
    func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {
        switch self {
        case .jpIC:
            JPICConverter.cardInfo(info)
        case .jpIC_SAPICA:
            JPICConverter.cardInfo(info)
        case .jpIC_IruCa:
            JPICConverter.cardInfo(info)
        case .cnTunion:
            CNTUnionConverter.cardInfo(info)
        case .hkOctopus:
            HKOctopusConverter.cardInfo(info)
        case .krOneCard:
            KROneCardConverter.cardInfo(info)
        case .twICash:
            TWICashConverter.cardInfo(info)
        case .jpNplus:
            JPNplusConverter.cardInfo(info)
        case .twEasyCard_old:
            TWEasyCardOldConverter.cardInfo(info)
        case .usClipper:
            USClipperConverter.cardInfo(info)
        case .jpDoCard:
            JPDoCardConverter.cardInfo(info)
        case .jpIC_icsca:
            JPICConverter.cardInfo(info)
        case .jpOKICA:
            JPOKICAConverter.cardInfo(info)
        case .jpRapica:
            JPRapicaConverter.cardInfo(info)
        case .idKAI:
            IDKAIConverter.cardInfo(info)
        case .spEZLink:
            SPEZLinkConverter.cardInfo(info)
        }
    }

    @MainActor
    func history(_ item: ResultHistory) -> DisplayHistory {
        switch self {
        case .jpIC:
            JPICConverter.history(item)
        case .jpIC_SAPICA:
            JPICConverter.history(item)
        case .jpIC_IruCa:
            JPICConverter.history(item)
        case .cnTunion:
            CNTUnionConverter.history(item)
        case .hkOctopus:
            HKOctopusConverter.history(item)
        case .krOneCard:
            KROneCardConverter.history(item)
        case .twICash:
            TWICashConverter.history(item)
        case .jpNplus:
            JPNplusConverter.history(item)
        case .twEasyCard_old:
            TWEasyCardOldConverter.history(item)
        case .usClipper:
            USClipperConverter.history(item)
        case .jpDoCard:
            JPDoCardConverter.history(item)
        case .jpIC_icsca:
            JPICConverter.history(item)
        case .jpOKICA:
            JPOKICAConverter.history(item)
        case .jpRapica:
            JPRapicaConverter.history(item)
        case .idKAI:
            IDKAIConverter.history(item)
        case .spEZLink:
            SPEZLinkConverter.history(item)
        }
    }
}
