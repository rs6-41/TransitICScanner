import SwiftUI

// 結果
struct Result: Hashable {
    var balance: Double?
    var isHistory: Bool
    var history: [ResultHistory]?
    var info: ResultCardInfo?
    var converter: ConverterType
    var isLastHide: Bool
    var description: String
    var savedAt:Date? = Date.now
    var fullLog:String? = ""
}

// 履歴データ
struct ResultHistory: Hashable, Codable {
    var processType: UInt8? = nil
    var processType4: UInt32? = nil
    var date: DateComponents
    var balance: Double
    var amount: Double?
    var lineIn: UInt8
    var stationIn: UInt8
    var lineOut: UInt8
    var stationOut: UInt8
    var transactionId: Int
    var mappingID: String = ""
}

// カード情報
struct ResultCardInfo: Hashable, Codable {
    var idm: String
    var name: String
    var nameShort: String
    var displayName: String?
    var iconName: String?
    var currencyType: currencyType?
    var type: String
    var serial: String?
    var version: String?
    var validDate: String?
    var issueInfo: issueInfo?
}

//発行情報
struct issueInfo: Hashable, Codable {
    var region: String //発行地域
    var area: String? //発行都市
    var city: String? //発行エリア
    var otherAreaInfo: String? //その他の情報
    var issuer: String? //発行者
    var date: Date? //発行日
}

struct DisplayHistory: Hashable {
    var date: String
    var processType: String
    var processType4: String?
    var balance: Double
}

struct DisplayCardInfo: Hashable {
    var idm: String
    var name: String
    var nameShort: String
    var displayName: String?
    var iconName: String?
    var currencyType: currencyType
    var type: String
    var typeLocalizeTable: String? = nil
}
