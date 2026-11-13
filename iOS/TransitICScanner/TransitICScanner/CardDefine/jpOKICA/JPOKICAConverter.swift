import Foundation

enum JPOKICAConverter {

    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {

        DisplayHistory(
            date: formatDate(history.date),
            processType: convertProcessType(
                history.processType4 ?? 0
            ),
            balance: Double(history.balance)
        )
    }

    private static func formatDate(
        _ date: DateComponents
    ) -> String {

        guard let year = date.year,
            let month = date.month,
            let day = date.day
        else {
            return String(localized: "unknown")
        }

        return "\(year)/\(month)/\(day)"
    }

    private static func convertProcessType(
        _ value: UInt32
    ) -> String {

        switch value {

        case 0x16010002:
            return String(localized: "result.history.fare")

        case 0x08020000:
            return String(localized: "result.history.charge")

        case 0x08480000,
            0x08480400:
            return String(localized: "result.history.charge")

        case 0x051F0000:
            return String(localized: "result.history.charge.bus")

        case 0x050F000F:
            return String(localized: "result.history.bus")

        case 0x08070000:
            return String(localized: "result.history.new")

        case 0x1F1F0000:
            return String(localized: "result.history.charge")

        default:
            return String(localized: "result.history.other")
        }
    }

    static func cardInfo(
        _ info: ResultCardInfo
    ) -> DisplayCardInfo {

        DisplayCardInfo(
            idm: info.idm,
            name: info.name,
            nameShort: info.nameShort,
            currencyType: info.currencyType ?? .jpy,
            type: info.type
        )
    }
}
