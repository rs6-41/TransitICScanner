import Foundation

enum jpNplus_Converter {
    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {
        DisplayHistory(
            date: formatDate(history.date),
            processType: convertProcessType(history.processType),
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

    private static func convertProcessType(_ value: UInt8) -> String {
        switch value {
            case 0x10: return String(localized:"result.history.new") //新規発行
            case 0x40: return String(localized:"result.history.bus") //バス
            case 0x50: return String(localized:"result.history.charge") //チャージ
            case 0xc0: return String(localized:"result.history.shopping") //物販
            default: return String(localized:"result.history.other") //不明
        }
    }
    
    static func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {

        DisplayCardInfo(
            idm: info.idm,
            name: info.name,
            nameShort: info.nameShort,
            currencyType:info.currencyType ?? .jpy,
            type:info.type
        )
    }    
}
