import Foundation

//TODO: 暫定的に未変換のため、調査後に変換実装を行う

enum jpDoCard_Converter {

    static func balance(_ value: Int) -> String {
        return String(format: "%.2f", value)
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
    
    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {
        DisplayHistory(
            date: formatDate(history.date),
            processType: String(history.processType),
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
}
