import Foundation

enum jpIC_Converter {
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
            return String(localized:"unknown")
        }

        return "\(year)/\(month)/\(day)"
    }

    //参考：https://github.com/Kazzz/nfc-felica/blob/master/src/net/kazzz/felica/suica/Suica.java
    private static func convertProcessType(_ value: UInt8) -> String {
        switch value {
        case 0x01: return String(localized:"result.history.fare") // 支払い
        case 0x02: return String(localized:"result.history.charge") //チャージ
        case 0x03: return String(localized:"result.history.ticket") //券購入
        case 0x04: return String(localized:"result.history.fare_collection.jr") //乗越精算(JR)
        case 0x05: return String(localized:"result.history.ticket.platform") //入場券(同駅のみ)
        case 0x06: return String(localized:"result.history.counter.cancel") //入場取り消し
        case 0x07: return String(localized:"result.history.new") //新規発行
        case 0x08: return String(localized:"result.history.end") //入場取り消し
        case 0x0d: return String(localized:"result.history.bus") //バス
        case 0x0f: return String(localized:"result.history.bus") //バス
        case 0x11: return String(localized:"result.history.reissue") //再発行
        case 0x13: return String(localized:"result.history.shinkansen") //新幹線
        case 0x14: return String(localized:"result.history.charge_auto") //オートチャージ(入場)
        case 0x15: return String(localized:"result.history.charge_auto") //オートチャージ(出場)
        case 0x1f: return String(localized:"result.history.charge.bus") //バスでチャージ
        case 0x23: return String(localized:"result.history.ticket_bus") //バス企画券購入
        case 0x46: return String(localized:"result.history.shopping") //物販
        case 0x49: return String(localized:"result.history.charge.store") //レジでチャージ
        case 0x4a: return String(localized:"result.history.shopping.cancel") //物販キャンセル
        case 0x4b: return String(localized:"result.history.shopping.platform") //入場物販
        case 0xc6: return String(localized:"result.history.shopping.cash") //現金併用物販
        case 0xcb: return String(localized:"result.history.shopping.platform.cash") //入場現金併用物販
        case 0x84: return String(localized:"result.history.fare_collection.other") //他社精算
        case 0x85: return String(localized:"result.history.platform.other") //他社入場精算
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

/// 未実装：駅判別
/// https://ja.ysrl.org/atc/station-code.html
