import Foundation

enum SPFlashPayConverter {
    static func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {
        DisplayCardInfo(
            idm: info.idm, name: info.name, nameShort: info.nameShort, displayName: info.displayName,
            iconName: info.iconName, currencyType: info.currencyType ?? .sgd, type: info.type
        )
    }

    static func history(_ item: ResultHistory) -> DisplayHistory {
        let label: String
        switch item.processType {
        case 0x30: label = "result.history.rail"
        case 0x31: label = "result.history.bus"
        case 0x03, 0x75: label = "result.history.charge"
        case 0x01: label = "result.history.shopping"
        default: label = "result.history.other"
        }
        return DisplayHistory(date: "", processType: label, balance: item.balance)
    }
}
