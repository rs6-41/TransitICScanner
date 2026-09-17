import SwiftUI

// サンプルデータを取得する
func getResultSample(model:CardInfo) -> Result {
    let sample = model.sample
    let info = ResultCardInfo(idm: sample.idm, name: model.name, nameShort: model.scanOption.nameShort, iconName:model.logo, currency: model.scanOption.currency, type: sample.type)
    let result = Result(balance: sample.balance,isHistory: true, history: sample.history, info: info,converter: model.scanOption.converter,isLastHide: false,description: model.scand_description)
    return result
}
