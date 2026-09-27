import Foundation

enum hkOctopus_Converter {

    static func balance(_ value: Int) -> String {
        let hkd = Double(value) / 10.0
        return String(format: "%.2f", hkd)
    }

    static func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {
        DisplayCardInfo(
            idm: info.idm,
            name: info.name,
            nameShort: info.nameShort,
            currencyType: info.currencyType ?? .hkd,
            type: info.type
        )
    }
    
    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {
        DisplayHistory(
            date: "",
            processType: "",
            balance: 0.0
        )
    }
}
