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
}

// 履歴データ
struct ResultHistory: Hashable, Codable {
    var processType: UInt8
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
    var currency: String? //廃止
    var currencyType: currencyType?
    var type: String
    var serial: String?
    var version: String?
    var validDate: String?
}

struct DisplayHistory: Hashable {
    var date: String
    var processType: String
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
