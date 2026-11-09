import SwiftUI

// 結果
struct ScanResult: Hashable {
    var balance: Double?
    var isHistory: Bool
    var history: [ResultHistory]?
    var info: ResultCardInfo?
    #if !os(watchOS)
    var converter: ConverterType
    #endif
    var isLastHide: Bool
    var description: String
    var savedAt: Date? = Date.now
    var fullLog: String? = ""
    var converterTypeRaw: String? = nil
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

extension ResultHistory {
    /// カード内に連番がない場合に、取引を一意に識別する `transactionId` を作る。
    ///
    /// 保存時は `transactionId` が同じ履歴を重複として扱うため、
    /// 同じ取引からは常に同じ値になり、別の取引とは衝突しにくい値にする必要がある。
    /// - Parameters:
    ///   - date: 取引日時（秒まで使う）
    ///   - processType: 取引種別
    ///   - balance: 取引後の残高（下位 16 bit を使う）
    static func makeTransactionID(date: DateComponents, processType: UInt8, balance: Int) -> Int {
        let year = max((date.year ?? 2000) - 2000, 0)
        let timeKey =
            ((((year * 12 + (date.month ?? 0)) * 31 + (date.day ?? 0)) * 24
                + (date.hour ?? 0)) * 60 + (date.minute ?? 0)) * 60 + (date.second ?? 0)
        let discriminator = Int(processType) << 16 | (balance & 0xFFFF)
        return timeKey << 24 | discriminator
    }
}

// カード情報
struct ResultCardInfo: Hashable, Codable {
    var idm: String
    var name: String
    var nameShort: String
    var displayName: String?
    var iconName: String?
    var currencyType: CurrencyType?
    var type: String
    var serial: String?
    var version: String?
    var validDate: String?
    var issueInfo: IssueInfo?
}

//発行情報
struct IssueInfo: Hashable, Codable {
    var region: String  //発行地域
    var area: String?  //発行都市
    var city: String?  //発行エリア
    var otherAreaInfo: String?  //その他の情報
    var issuer: String?  //発行者
    var date: Date?  //発行日
    var expiry: Date?  //有効期限
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
    var currencyType: CurrencyType
    var type: String
    var typeLocalizeTable: String? = nil
}
