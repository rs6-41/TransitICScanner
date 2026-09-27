import SwiftUI
import WidgetKit

struct BalanceWidgetModel: Hashable,Codable {
    var DisplayName: String?
    var balance: Double?
    var idm: String
    var savedAt:Date?
}

func getSavedWidgetData() -> [BalanceWidgetModel] {
    let sharedDefaults = UserDefaults(suiteName: "group.com.rs6apps.TransitICScanner")
    
    if let savedData = sharedDefaults?.data(forKey: "widgetDatas"),
       let decodedModels = try? JSONDecoder().decode([BalanceWidgetModel].self, from: savedData) {
        var savedWidgetData = decodedModels
        savedWidgetData.insert(notSelectionModel, at: 0)
        return savedWidgetData
    } else {
        return []
    }
}

//未選択
let notSelectionModel = BalanceWidgetModel(
    DisplayName:String(localized:"widget.balance.placeholder.notSelection"),
    balance:0.0,
    idm: "system.option.notSelection",
    savedAt:Date.now
)

//プレースホルダー

let placeholderModel = BalanceWidgetModel(
    DisplayName:String(localized:"widget.balance.placeholder.displayName"),
    balance:5000.0,
    idm: "PLACEHOLDER",
    savedAt:Date.now
)

//読み込みエラー時
let snapshotModel = BalanceWidgetModel(
    DisplayName:String(localized:"unknown"),
    balance:0,
    idm: "UNKWNOWN",
    savedAt:nil
)
