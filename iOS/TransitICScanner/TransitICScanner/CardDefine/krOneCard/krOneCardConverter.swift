import Foundation

enum krOneCard_Converter {

    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {
        DisplayHistory(
            date: formatDate(history.date),
            processType: convertProcessType(history),
            balance: Double(history.balance)
        )
    }

    private static func formatDate(_ date: DateComponents) -> String {
        guard let year = date.year,
              let month = date.month,
              let day = date.day else {
            return String(localized:"unknown")
        }

        return "\(year)/\(month)/\(day)"
    }

    private static func convertProcessType(_ history: ResultHistory) -> String {
        if history.processType == 0x01 && history.balance == 0 && history.amount == 0 {
            return String(localized:"result.history.new")
        }
        return convertProcessType(history.processType)
    }

    private static func convertProcessType(_ value: UInt8) -> String {
        switch value {
        case 0x01:
            return String(localized:"result.history.fare")
        case 0x02:
            return String(localized:"result.history.charge")
        default:
            return String(localized:"result.history.other")
        }
    }

    static func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {
        DisplayCardInfo(
            idm: info.idm,
            name: info.name,
            nameShort: info.nameShort,
            currencyType: info.currencyType ?? .krw,
            type: info.type
        )
    }
}
