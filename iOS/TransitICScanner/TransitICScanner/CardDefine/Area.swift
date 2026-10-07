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
    case sg = "cardList.area.sg"
    
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
        }
    }
    
    func region() -> regionType {
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
        }
    }
}

enum regionType: String, CaseIterable,Codable {
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

struct regionList:Hashable {
    var first: regionType
    var second: regionType?
}
let regionLists = [
    regionList(first:.eastAsia,second:.japanLocal),
    regionList(first:.southEastAsia),
    regionList(first:.centralAsia),
    regionList(first:.southAsia),
    regionList(first:.middleEastAsia),
    regionList(first:.europa),
    regionList(first:.northAmerica),
    regionList(first:.latinAmerica),
    regionList(first:.oceania),
    regionList(first:.africa)
]


enum currencyType: String, CaseIterable,Codable {
    case jpy
    case rmb
    case hkd
    case ntd
    case krw
    case usd
    case sgd // シンガポールドル
    
    func getLocalize(_ price:String) -> LocalizedStringKey {
        switch self {
            case .jpy: return "currency.jpy.\(price)"
            case .rmb: return "currency.rmb.\(price)"
            case .hkd: return "currency.hkd.\(price)"
            case .ntd: return "currency.ntd.\(price)"
            case .krw: return "currency.krw.\(price)"
            case .usd: return "currency.usd.\(price)"
            case .sgd: return "currency.sgd.\(price)"
        }
    }
}
