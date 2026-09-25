import WidgetKit
import SwiftUI

//ウィジェット本体(placeholderModelはテスト)

struct SmallBalanceWidget: Widget {
    let kind: String = "com.rs6apps.TransitICScanner.BalanceWidget.small"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SmallWidgetConfigurationAppIntent.self, provider: SmallBalanceWidgetProvider()) { entry in
            SmallBalanceWidgetView(entry: entry)
                .containerBackground(.ultraThinMaterial, for: .widget)
        }
        .configurationDisplayName("widget.balance.small.title")
        .description("widget.balance.smalldescription")
        .supportedFamilies([.systemSmall])
    }
}

// サンプルモデル生成
extension SmallWidgetConfigurationAppIntent {
    fileprivate static var placeholder: SmallWidgetConfigurationAppIntent {
        let intent = SmallWidgetConfigurationAppIntent()
        return intent
    }
}

#Preview(as: .systemSmall) {
    SmallBalanceWidget()
} timeline: {
    SmallBalanceWidgetEntry(date: .now, configuration: .placeholder, models: placeholderModel)
}
