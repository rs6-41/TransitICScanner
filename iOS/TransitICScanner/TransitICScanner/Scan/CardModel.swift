import SwiftUI
import Foundation
import CoreNFC

/// カード情報を定義する
struct CardInfo {
    let logo: String
    let name: String
    let area: String
    let countryCode: [String]
    let description: String?
    let scand_description: String
    let searchWords: [String]
    let scanOption: ScanOption
    let infomation: AnyView?
}

struct ScanOption {
    var name: String //定義名
    let nameShort: String
    var scanType: ScanType
    var pollingOption:NFCTagReaderSession.PollingOption
    var felicaSystemCodes: [String]? //Felicaシステムコードを設定
    var url: URL?
    var historyCount: Int //履歴の取得件数
    var currency: String //通貨単位
    var converter: ConverterType
}

enum ScanType {
    case nfc
    case scraping
}

protocol CardConverter {
    func convertCardInfo(_ data: Any) -> Any
    func convertHistory(_ data: Any) -> Any
}

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
