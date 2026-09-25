import WidgetKit
import AppIntents
import SwiftUI

struct SmallWidgetConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource {
        "widget.balance.setting.small.title"
    }

    static var description: IntentDescription {
        "widget.balance.setting.small.description"
    }

    @Parameter(title: "widget.balance.setting.small.card")
    var card: CardBalanceModel?
}
