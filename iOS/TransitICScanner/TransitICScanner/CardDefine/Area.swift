import SwiftUI

enum AreaType: String,CaseIterable {
    case jp = "cardList.area.jp"
    case cn = "cardList.area.cn"
    case hk = "cardList.area.hk"
    case kr = "cardList.area.kr"
    case tw = "cardList.area.tw"
    case mo = "cardList.area.mo"
    case kp = "cardList.area.kp"
    case us = "cardList.area.us"
    case sg = "cardList.area.sg"
    case id = "cardList.area.id"
    
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
            case .sg: return "cardList.area.sg.sortName"
            case .id: return "cardList.area.id.sortName"
        }
    }
    
    func region() -> RegionType {
        switch self {
            case .jp: return .japanLocal
            case .cn: return .eastAsia
            case .hk: return .eastAsia
            case .kr: return .eastAsia
            case .tw: return .eastAsia
            case .mo: return .eastAsia
            case .kp: return .eastAsia
            case .us: return .northAmerica
            case .sg: return .southEastAsia
            case .id: return .southEastAsia
        }
    }
}

enum RegionType: String, CaseIterable,Codable {
    case eastAsia //東アジア
    case japanLocal // 日本ローカル
    case southEastAsia //東南アジア
    case centralAsia // 中央アジア
    case southAsia // 南アジア
    case middleEastAsia // 中東
    case europa // ヨーロッパ
    case northAmerica //北アメリカ
    case latinAmerica // 中南米
    case oceania // オセアニア
    case africa // アフリカ
    
    func name() -> String {
        switch self {
            case .eastAsia: return "region.eastAsia"
            case .japanLocal: return "region.japanLocal"
            case .southEastAsia: return "region.southEastAsia"
            case .centralAsia: return "region.centralAsia"
            case .southAsia: return "region.southAsia"
            case .middleEastAsia: return "region.middleEastAsia"
            case .europa: return "region.europa"
            case .northAmerica: return "region.northAmerica"
            case .latinAmerica: return "region.latinAmerica"
            case .oceania: return "region.oceania"
            case .africa: return "region.africa"
        }
    }
    
    func icon() -> String {
        switch self {
            case .eastAsia: return "globe.asia.australia"
            case .japanLocal: return "globe.asia.australia"
            case .southEastAsia: return "globe.asia.australia"
            case .centralAsia: return "globe.central.south.asia"
            case .southAsia: return "globe.central.south.asia"
            case .middleEastAsia: return "globe.asia.australia"
            case .europa: return "globe.europe.africa"
            case .northAmerica: return "globe.americas"
            case .latinAmerica: return "globe.americas"
            case .oceania: return "globe.asia.australia"
            case .africa: return "globe.europe.africa"
        }
    }
}

struct RegionList:Hashable {
    var first: RegionType
    var second: RegionType?
}
let regionLists = [
    RegionList(first:.eastAsia,second:.japanLocal),
    RegionList(first:.southEastAsia),
    RegionList(first:.centralAsia),
    RegionList(first:.southAsia),
    RegionList(first:.middleEastAsia),
    RegionList(first:.europa),
    RegionList(first:.northAmerica),
    RegionList(first:.latinAmerica),
    RegionList(first:.oceania),
    RegionList(first:.africa)
]


enum CurrencyType: String, CaseIterable,Codable {
    case jpy
    case rmb
    case hkd
    case ntd
    case krw
    case kpw
    case usd
    case sgd // シンガポールドル
    case idr // インドネシア・ルピア
    
    func getLocalize(_ price:String) -> LocalizedStringKey {
        switch self {
            case .jpy: return "currency.jpy.\(price)"
            case .rmb: return "currency.rmb.\(price)"
            case .hkd: return "currency.hkd.\(price)"
            case .ntd: return "currency.ntd.\(price)"
            case .krw: return "currency.krw.\(price)"
            case .kpw: return "currency.kpw.\(price)"
            case .usd: return "currency.usd.\(price)"
            case .sgd: return "currency.sgd.\(price)"
            case .idr: return "currency.idr.\(price)"
        }
    }
}
