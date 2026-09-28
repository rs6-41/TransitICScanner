import WidgetKit
import SwiftUI

//ウィジェット本体

struct ListBalanceWidget: Widget {
    let kind: String = "com.rs6apps.TransitICScanner.BalanceWidget.list"
    
    var widgetFamilies:[WidgetFamily] {
        if #available(iOS 27.0, *) {
            return [.systemMedium, .systemLarge, .systemExtraLargePortrait]
        } else {
            return [.systemMedium, .systemLarge]
        }
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ListWidgetConfigurationAppIntent.self, provider: ListBalanceWidgetProvider()) { entry in
            ListBalanceWidgetView(entry: entry)
                .containerBackground(.ultraThinMaterial, for: .widget)
        }
        .configurationDisplayName("widget.balance.setting.list.title")
        .description("widget.balance.setting.list.description")
        .supportedFamilies(widgetFamilies)
    }
}

// サンプルモデル生成
extension ListWidgetConfigurationAppIntent {
    fileprivate static var placeholder: ListWidgetConfigurationAppIntent {
        let intent = ListWidgetConfigurationAppIntent()
        return intent
    }
}

#Preview(as: .systemMedium) {
    ListBalanceWidget()
} timeline: {
    ListBalanceWidgetEntry(date: .now, configuration: .placeholder, models: [placeholderModel], updateDate: Date.now)
}
