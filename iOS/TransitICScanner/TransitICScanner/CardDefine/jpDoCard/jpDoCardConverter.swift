import Foundation

enum jpDoCard_Converter {
    static func balance(
        _ value: Int
    ) -> String {
        return String(
            format: "%.2f",
            value
        )
    }

    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {
        DisplayHistory(
            date: formatDate(history.date),
            processType: convertProcessType(
                Int(history.processType ?? 0), amount: Int(history.amount ?? 0)
            ),
            balance: Double(history.balance)
        )
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

    private static func formatDate(
        _ date: DateComponents
    ) -> String {

        guard let year = date.year,
              let month = date.month,
              let day = date.day else {
            return String(localized: "unknown")
        }

        return "\(year)/\(month)/\(day)"
    }

    private static func convertProcessType(
        _ value: Int, amount: Int
    ) -> String {
        switch value {
        case 0x02, 0x03, 0x07, 0x12:
            return String(localized: "result.history.fare")
        case 0x08, 0x15, 0x1F, 0x20:
            return String(localized: "result.history.charge")
        case 0x1E, 0x14, 0x2D:
            return String(localized: "result.history.new")
        default:
            return String(localized: "result.history.other")
        }
    }
}
