import Foundation

/// 現行のカード識別子と、旧バージョンが保存した文字列との互換性を管理する。
nonisolated enum CardIdentity {
    static func canonicalID(_ identifier: String) -> String {
        switch identifier {
        case "idKMT": "idKAI"
        case "spEZLink": "spFlashPay"
        default: identifier
        }
    }

    static func localizationKey(_ key: String) -> String {
        switch key {
        case "cardList.idKMT": return "cardList.idKAI"
        case "cardList.idKMT.sortName": return "cardList.idKAI.sortName"
        case "cardList.idKMT.description": return "cardList.idKAI.description"
        case "idKMT.short": return "idKAI.short"
        case "idKMT.scand.description": return "idKAI.scand.description"
        case "card.KMT": return "card.idKAI"
        default: return key
        }
    }

    static func assetName(_ name: String) -> String {
        name == "idKMT" ? "idKAI" : name
    }
}
