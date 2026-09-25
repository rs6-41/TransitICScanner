import WidgetKit
import AppIntents
import SwiftUI

struct ListWidgetConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource {
        "widget.balance.setting.list.title"
    }

    static var description: IntentDescription {
        "widget.balance.setting.list.description"
    }

    @Parameter(title: "widget.balance.setting.list.card")
    var card: [CardBalanceModel]?
}
