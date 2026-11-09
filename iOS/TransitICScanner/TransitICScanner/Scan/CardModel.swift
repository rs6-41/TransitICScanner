import SwiftUI
import Foundation

#if !os(watchOS)
import CoreNFC
#endif

/// カード情報を定義する
struct CardInfo {
    let logo: String
    let name: String
    let sortName: String
    let area: AreaType
    let countryCode: [String]
    let prefectures: [String]?
    let regionOption: RegionType?  //地域分類に例外的な指定をする（通常はAreaTypeから判定）
    let description: String?
    let scannedDescription: String
    let searchWords: [String]
    let scanOption: ScanOption
    let information: AnyView?
    let sample: ResultSample
}

/// カード定義の識別子。読取処理の分岐はこの enum で網羅的に行う。
/// rawValue は保存データやローカライズキーで使われるため変更しないこと。
enum CardID: String, CaseIterable {
    case jpIC
    case jpIC_SAPICA
    case jpIC_IruCa
    case jpIC_icsca
    case cnTunion
    case hkOctopus
    case krOneCard
    case twICash
    case jpNplus
    case twEasyCard_old
    case usClipper
    case jpDoCard
    case jpOKICA
    case jpRapica
    case idKMT
    case spFlashPay
}

struct ScanOption {
    var id: CardID  //定義名
    var name: String { id.rawValue }
    let nameShort: String
    var scanType: ScanType
    #if os(watchOS)
    var pollingOption: String
    #else
    var pollingOption: NFCTagReaderSession.PollingOption
    #endif
    var felicaSystemCodes: [String]?  //Felicaシステムコードを設定
    var url: URL?
    var historyCount: Int  //履歴の取得件数
    var currencyType: CurrencyType  //通貨単位
    var converter: ConverterType
    var scrapingView: (() -> AnyView)?
}

// サンプルデータ
let sampleDay1 = DateComponents(year: 2025, month: 12, day: 29, hour: 10, minute: 32)
let sampleDay2 = DateComponents(year: 2025, month: 12, day: 29, hour: 19, minute: 21)
let sampleDay3 = DateComponents(year: 2026, month: 1, day: 3, hour: 12, minute: 58)

struct ResultSample {
    let balance: Double
    let idm: String
    let type: String
    let history: [ResultHistory]
}

//スキャン種別
enum ScanType {
    case nfc
    case scraping
    case external
}

enum ScanReaderSource: String, CaseIterable, Identifiable {
    case builtIn
    case external

    var id: String { rawValue }
}

/// Reader-independent APDU exchange used by card parsers that support ISO 7816.
typealias APDUSend = (
    _ cla: UInt8,
    _ ins: UInt8,
    _ p1: UInt8,
    _ p2: UInt8,
    _ data: Data,
    _ le: Int
) async throws -> (Data, UInt8, UInt8)

extension CardInfo {
    func matchesSearch(_ text: String) -> Bool {
        guard !text.isEmpty else {
            return true
        }

        let localizedName = String(
            localized: String.LocalizationValue(name)
        )

        if localizedName.localizedCaseInsensitiveContains(text) {
            return true
        }

        return searchWords.contains { key in
            let localizedWord = String(
                localized: String.LocalizationValue(key)
            )

            return localizedWord.localizedCaseInsensitiveContains(text)
        }
    }
}
