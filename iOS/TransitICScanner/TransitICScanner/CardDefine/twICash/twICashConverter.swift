import Foundation

enum twICash_Converter {
    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {
        DisplayHistory(
            date: formatDate(history.date),
            processType: convertProcessType(
                history.mappingID
            ),
            balance: history.balance
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
        _ mappingID: String
    ) -> String {
        let value = mappingID.uppercased()

        if value == "KRT" ||
           value.hasPrefix("KRT") {
            return String(localized:"result.history.mrt.tw.kaohsiung")
        }

        if value == "TRT" ||
           value.hasPrefix("TRT") {
            return String(localized:"result.history.mrt.tw.taipei")
        }

        if value == "TRA" ||
           value.hasPrefix("TRA") {
            return String(localized:"result.history.taiwan_railway")
        }

        if value == "TMC" ||
           value.hasPrefix("TMC") {
            return String(localized:"result.history.mrt.tw.taoyuan")
        }

        if value == "TCT" ||
           value.hasPrefix("TCT") {
            return String(localized:"result.history.mrt.tw.taizhong")
        }

        if value == "THR" {
            return String(localized:"result.history.hsr")
        }

        if value == "TTB" ||
           value == "KPB" {
            return String(localized:"result.history.cycle")
        }

        if isParkingCode(value) {
            return String(localized:"result.history.parking")
        }

        if value == "KCS" {
            return String(localized:"result.history.ferry")
        }

        if value == "TLR" ||
           value == "KLR" ||
           value.hasPrefix("TLR") {
            return String(localized:"result.history.lrt")
        }

        if isBusNumber(value) {
            return String(localized:"result.history.bus")
        }

        let busCodes: Set<String> = [
            "ADB",
            "AIR",
            "ALS",
            "CAP",
            "CHB",
            "CLB",
            "CNB",
            "CPB",
            "CTB",
            "CYB",
            "DAN",
            "DDB",
            "EDA",
            "EIB",
            "ETT",
            "FHB",
            "FYB",
            "GDB",
            "GTC",
            "GYB",
            "HCB",
            "HHB",
            "HLB",
            "HTB",
            "JSB",
            "JYB",
            "KCB",
            "KHB",
            "KIN",
            "KLB",
            "KML",
            "KSB",
            "MLB",
            "MTC",
            "ORB",
            "NTB",
            "RYB",
            "SCB",
            "SDB",
            "SEB",
            "SEK",
            "SFB",
            "SHI",
            "SIB",
            "SLB",
            "SLS",
            "SNB",
            "STB",
            "T02",
            "TCB",
            "TPE",
            "TSB",
            "TYB",
            "UBG",
            "UBS",
            "YLB",
            "ZBC",
            "ZNB"
        ]

        if busCodes.contains(value) {
            return String(localized:"result.history.bus")
        }

        return String(localized:"result.history.fare")
    }

    private static func isParkingCode(
        _ value: String
    ) -> Bool {
        if value == "I00" ||
           value == "I01" {
            return true
        }

        guard value.count == 3,
              value.first == "P" else {
            return false
        }

        return value.dropFirst().allSatisfy {
            $0.isLetter || $0.isNumber
        }
    }

    private static func isBusNumber(
        _ value: String
    ) -> Bool {
        guard value.count >= 2,
              value.first == "B" else {
            return false
        }

        let numberString = String(
            value.dropFirst()
        )

        guard let number = Int(numberString) else {
            return false
        }

        return number >= 1 && number <= 99
    }

    static func cardInfo(
        _ info: ResultCardInfo
    ) -> DisplayCardInfo {
        DisplayCardInfo(
            idm: info.idm,
            name: info.name,
            nameShort: info.nameShort,
            currencyType: info.currencyType ?? .ntd,
            type: info.type
        )
    }
}
