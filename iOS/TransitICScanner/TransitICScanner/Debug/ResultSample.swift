import SwiftUI

// サンプルデータを取得する
func makeSampleResult(model: CardInfo) -> ScanResult? {
    guard let sample = model.sample else { return nil }
    let info = ResultCardInfo(
        idm: sample.idm, name: model.name, nameShort: model.scanOption.nameShort,
        displayName: localizedString(model.name),
        iconName: model.logo, currencyType: model.scanOption.currencyType, type: sample.type)
    let result = ScanResult(
        balance: sample.balance, isHistory: true, history: sample.history, info: info,
        converter: model.scanOption.converter, isLastHide: false, description: model.scannedDescription,
        savedAt: Date.now)
    return result
}
