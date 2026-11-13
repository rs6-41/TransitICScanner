import Foundation

enum JPRapicaConverter {
    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {
        DisplayHistory(
            date: formatDate(history.date),
            processType: convertProcessType(history.processType ?? 0),
            balance: Double(history.balance)
        )
    }

    // Rapicaの履歴には時刻があるので、あれば併記する
    private static func formatDate(_ date: DateComponents) -> String {
        guard let year = date.year,
            let month = date.month,
            let day = date.day
        else {
            return String(localized: "unknown")
        }

        // 年が 0 の場合は年情報なしとして月日のみ表示
        let ymd = year == 0 ? "\(month)/\(day)" : "\(year)/\(month)/\(day)"

        if let hour = date.hour, let minute = date.minute {
            return ymd + String(format: " %02d:%02d", hour, minute)
        }
        return ymd
    }

    // 利用種別 (履歴 byte12)
    private static func convertProcessType(_ value: UInt8) -> String {
        switch value {
        case 0x00...0x0F: return String(localized: "result.history.new")  //新規発行
        case 0x10...0x1F: return String(localized: "result.history.register")  //登録
        case 0x20, 0x40: return String(localized: "result.history.charge")  //チャージ
        case 0x30...0x3F: return String(localized: "result.history.boarding")  //乗車
        case 0x22, 0x41...0x4F: return String(localized: "result.history.fare")  //降車
        default: return String(localized: "result.history.other")  //不明
        }
    }

    static func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {

        DisplayCardInfo(
            idm: info.idm,
            name: info.name,
            nameShort: info.nameShort,
            currencyType: info.currencyType ?? .jpy,
            type: info.type
        )
    }
}
