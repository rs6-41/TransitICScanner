import Foundation

enum TWEasyCardOldConverter {
    static func balance(_ value: Int) -> String {
        let hkd = Double(value) / 10.0
        return String(format: "%.2f", hkd)
    }

    static func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {
        DisplayCardInfo(
            idm: info.idm,
            name: info.name,
            nameShort: info.nameShort,
            currencyType: info.currencyType ?? .ntd,
            type: info.type
        )
    }

    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {
        let dc = history.date
        let date = String(
            format: "%04d/%02d/%02d %02d:%02d",
            dc.year ?? 0,
            dc.month ?? 0,
            dc.day ?? 0,
            dc.hour ?? 0,
            dc.minute ?? 0
        )

        let process: String
        switch history.processType {
        case 1:
            process = String(localized: "result.history.fare")
        case 2:
            process = String(localized: "result.history.charge")
        default:
            process = String(localized: "result.history.other")
        }

        return DisplayHistory(
            date: date,
            processType: process,
            balance: history.balance
        )
    }
}
