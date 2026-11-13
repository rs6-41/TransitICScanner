import SwiftUI

//変数で扱うためのローカライズ値を取得する（表示には使用しない）
func localizedString(_ key: String) -> String {
    let localizationValue = String.LocalizationValue(stringLiteral: key)
    let localized = String(localized: localizationValue)
    return localized
}
