
import Foundation

enum idKMT_Converter {

    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {
        DisplayHistory(
            date: formatDate(history.date),
            processType: convertProcessType(history.processType ?? 0),
            balance: Double(history.balance)
        )
    }

    private static func formatDate(_ date: DateComponents) -> String {
        guard let year = date.year,
              let month = date.month,
              let day = date.day else {
            return String(localized: "unknown")
        }

        guard let hour = date.hour,
              let minute = date.minute else {
            return "\(year)/\(month)/\(day)"
        }

        return String(
            format: "%d/%d/%d %02d:%02d",
            year,
            month,
            day,
            hour,
            minute
        )
    }

    private static func convertProcessType(_ value: UInt8) -> String {
        switch value {
        case 0:
            return String(localized: "result.history.ticket")
        case 1:
            return String(localized: "result.history.fare")
        case 2:
            return String(localized: "result.history.shopping")
        default:
            return String(localized: "result.history.other")
        }
    }

    static func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {
        DisplayCardInfo(
            idm: info.idm,
            name: info.name,
            nameShort: info.nameShort,
            currencyType: info.currencyType ?? .idr,
            type: info.type
        )
    }
}
