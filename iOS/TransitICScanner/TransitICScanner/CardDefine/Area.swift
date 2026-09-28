import SwiftUI

enum areaType: String,CaseIterable {
    case jp = "cardList.area.jp"
    case cn = "cardList.area.cn"
    case hk = "cardList.area.hk"
    case kr = "cardList.area.kr"
    case tw = "cardList.area.tw"
    case mo = "cardList.area.mo"
    case kp = "cardList.area.kp"
    case us = "cardList.area.us"
    
    //ソート名（doc/sortName.md参照）
    
    func sortName() -> String {
        switch self {
            case .jp: return "cardList.area.jp.sortName"
            case .cn: return "cardList.area.cn.sortName"
            case .hk: return "cardList.area.hk.sortName"
            case .kr: return "cardList.area.kr.sortName"
            case .tw: return "cardList.area.tw.sortName"
            case .mo: return "cardList.area.mo.sortName"
            case .kp: return "cardList.area.kp.sortName"
            case .us: return "cardList.area.us.sortName"
        }
    }
}

enum currencyType: String, CaseIterable,Codable {
    case jpy
    case rmb
    case hkd
    case ntd
    case krw
    case usd
    
    func getLocalize(_ price:String) -> LocalizedStringKey {
        switch self {
            case .jpy: return "currency.jpy.\(price)"
            case .rmb: return "currency.rmb.\(price)"
            case .hkd: return "currency.hkd.\(price)"
            case .ntd: return "currency.ntd.\(price)"
            case .krw: return "currency.krw.\(price)"
            case .usd: return "currency.usd.\(price)"
        }
    }
}
