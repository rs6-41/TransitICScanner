import Foundation

enum jpOKICA_Converter {

    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {

        DisplayHistory(
            date: formatDate(history.date),
            processType: convertProcessType(
                history.processType ?? 0
            ),
            balance: Double(history.balance)
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
        _ value: UInt8
    ) -> String {

        switch value {

        case 0x16: return String(localized: "result.history.fare")
        case 0x08:return String(localized: "result.history.charge")
        case 0x05: return String(localized: "result.history.bus")
        case 0x1F: return String(localized: "result.history.charge")
        default: return String(localized: "result.history.other")
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
