import Foundation

enum USClipperConverter {
    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {
        DisplayHistory(
            date: formatDate(history.date),
            processType: convertProcessType(
                history.processType ?? 0,
                UInt32(history.processType4 ?? 0)
            ),
            balance: Double(history.balance)
        )
    }

    private static func formatDate(_ date: DateComponents) -> String {
        guard let year = date.year,
            let month = date.month,
            let day = date.day
        else {
            return String(localized: "unknown")
        }

        let ymd = "\(year)/\(month)/\(day)"

        if let hour = date.hour, let minute = date.minute {
            return ymd + String(format: " %02d:%02d", hour, minute)
        }
        return ymd
    }

    // MARK: 事業者名
    private static func agencyName(_ code: UInt16) -> String {
        switch code {
        case 0x01: return "(AC Transit)"
        case 0x04: return "(BART)"
        case 0x06: return "(Caltrain)"
        case 0x08: return "(County Connection)"
        case 0x0B: return "(Golden Gate Transit)"
        case 0x0F: return "(SamTrans)"
        case 0x11: return "(VTA)"
        case 0x12: return "(Muni)"
        case 0x19: return "(Golden Gate Ferry)"
        case 0x1B: return "(SF Bay Ferry)"
        default: return ""
        }
    }

    // MARK: 交通種別
    // 実機で確認済み: 0x6F = BART / Muni Metro (鉄道系), 0x77 = Muni・Golden Gate Transit のバス
    // 未確認: 0x61, 0x75 = バス / 0x62 = 近郊鉄道 / 0x73 = フェリー
    private static func modeName(_ code: UInt16) -> String? {
        switch code {
        case 0x6F, 0x62: return String(localized: "result.history.rail")  //鉄道
        case 0x61, 0x75, 0x77: return String(localized: "result.history.bus")  //バス
        case 0x73: return String(localized: "result.history.ferry")  //フェリー
        default: return nil
        }
    }

    // processType: 0x01 = チャージ, 0x02 = 乗車(トリップ)
    // processType4: 上位16bit = 事業者, 下位16bit = 交通種別
    private static func convertProcessType(_ value: UInt8, _ type4: UInt32) -> String {
        let agency = UInt16((type4 >> 16) & 0xFFFF)
        let transport = UInt16(type4 & 0xFFFF)

        switch value {
        case 0x01:
            // チャージ: 事業者は機械の設置事業者
            return String(localized: "result.history.charge") + " \(agencyName(agency))"

        case 0x02:
            let name = agencyName(agency)
            if let mode = modeName(transport) {
                return "\(mode) \(name)"
            }
            return "\(name) \(agencyName(transport))"

        default:
            return String(localized: "result.history.other")
        }
    }

    static func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {

        DisplayCardInfo(
            idm: info.idm,
            name: info.name,
            nameShort: info.nameShort,
            currencyType: info.currencyType ?? .usd,
            type: info.type
        )
    }
}
