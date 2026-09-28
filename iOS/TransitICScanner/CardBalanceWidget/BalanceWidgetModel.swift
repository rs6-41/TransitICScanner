import SwiftUI
import WidgetKit

struct BalanceWidgetModel: Hashable,Codable {
    var DisplayName: String?
    var balance: Double?
    var currencyType: currencyType?
    var idm: String
    var icon: String?
    var savedAt:Date?
}

func getSavedWidgetData() -> [BalanceWidgetModel] {
    guard let sharedDefaults = UserDefaults(
        suiteName: AppGroup
    ) else {
        print("Widget: App Groupを取得できません")
        return []
    }

    guard let savedData = sharedDefaults.data(
        forKey: "widgetDatas"
    ) else {
        print("Widget: widgetDatasがありません")
        return []
    }

    print("Widget: widgetDatasあり")
    print("Widget: データサイズ =", savedData.count)

    do {
        let decodedModels = try JSONDecoder().decode(
            [BalanceWidgetModel].self,
            from: savedData
        )

        print("Widget: Decode成功")
        print("Widget: 件数 =", decodedModels.count)

        for model in decodedModels {
            print(
                "Widget:",
                model.idm,
                model.DisplayName ?? "nil",
                model.balance ?? 0
            )
        }

        var savedWidgetData = decodedModels
        savedWidgetData.insert(
            notSelectionModel,
            at: 0
        )

        return savedWidgetData

    } catch {
        print("Widget: Decode失敗")
        print("Widget:", error)

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
    currencyType:.usd,
    idm: "PLACEHOLDER",
    icon:"placeholderCard",
    savedAt:Date.now
)
