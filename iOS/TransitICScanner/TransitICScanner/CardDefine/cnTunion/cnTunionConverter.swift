import Foundation

enum cnTunion_Converter {

    static func balance(_ value: Int) -> String {
        let hkd = Double(value) / 10.0
        return String(format: "%.2f", hkd)
    }

    static func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {
        var type: String

        type = cnTunion_idCheck(iin: String(info.idm.prefix(9)))

        return DisplayCardInfo(
            idm: info.idm,
            name: info.name,
            nameShort: info.nameShort,
            currencyType: info.currencyType ?? .rmb,
            type: type
        )
    }

    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {
        let processType: String

        switch history.processType {
        case 0x02:
            processType = String(localized: "result.history.charge")

        case 0x03:
            processType = String(localized: "result.history.stationOperation")

        case 0x04:
            processType = String(localized: "result.history.fare")

        case 0x06:
            processType = String(localized: "result.history.fare")

        case 0x09:
            processType = String(localized: "result.history.compositeFare")

        default:
            processType = String(localized: "result.history.other")
        }

        return DisplayHistory(
            date: DateFormatter.localizedString(
                from: Calendar.current.date(from: history.date) ?? Date(),
                dateStyle: .short,
                timeStyle: .short
            ),
            processType: processType,
            balance: history.balance
        )
    }
}
