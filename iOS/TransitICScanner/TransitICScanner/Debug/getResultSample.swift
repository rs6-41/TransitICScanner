import SwiftUI

// サンプルデータを取得する
func getResultSample(model:CardInfo) -> ScanResult {
    let sample = model.sample
    let info = ResultCardInfo(idm: sample.idm, name: model.name, nameShort: model.scanOption.nameShort, displayName:Localize(model.name), iconName:model.logo, currencyType: model.scanOption.currencyType, type: sample.type)
    let result = ScanResult(balance: sample.balance,isHistory: true, history: sample.history, info: info,converter: model.scanOption.converter,isLastHide: false,description: model.scannedDescription, savedAt: Date.now)
    return result
}
