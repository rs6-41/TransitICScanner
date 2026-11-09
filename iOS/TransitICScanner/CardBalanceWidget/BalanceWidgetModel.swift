import SwiftUI
import WidgetKit

struct BalanceWidgetModel: Hashable,Codable {
    var DisplayName: String?
    var balance: Double?
    var currencyType: CurrencyType?
    var idm: String
    var icon: String?
    var savedAt:Date?
}

/// Widget 表示用データの保存先（App Group の UserDefaults）
enum WidgetDataStore {
    private static let key = "widgetDatas"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: StorageConfig.appGroup)
    }

    /// 保存済みデータを読み込む。データがない、または復元できない場合は空配列を返す。
    static func load() -> [BalanceWidgetModel] {
        guard let defaults else {
            print("Widget: App Groupを取得できません")
            return []
        }

        guard let data = defaults.data(forKey: key) else {
            return []
        }

        do {
            return try JSONDecoder().decode([BalanceWidgetModel].self, from: data)
        } catch {
            print("Widget: Decode失敗", error)
            return []
        }
    }

    /// 保存済みデータを変更して書き戻し、Widget を更新する。
    static func update(_ transform: (inout [BalanceWidgetModel]) -> Void) {
        var models = load()
        transform(&models)

        do {
            let data = try JSONEncoder().encode(models)
            defaults?.set(data, forKey: key)
        } catch {
            print("Widget: Encode失敗", error)
            return
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}

func getSavedWidgetData() -> [BalanceWidgetModel] {
    [notSelectionModel] + WidgetDataStore.load()
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
