import SwiftUI
import WidgetKit

struct SmallBalanceWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: SmallWidgetConfigurationAppIntent
    
    let models: [BalanceWidgetModel]
}

struct SmallBalanceWidgetProvider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> SmallBalanceWidgetEntry {
        SmallBalanceWidgetEntry(date: Date(), configuration: SmallWidgetConfigurationAppIntent(),models:placeholderModel)
    }

    func snapshot(for configuration: SmallWidgetConfigurationAppIntent, in context: Context) async -> SmallBalanceWidgetEntry {
        SmallBalanceWidgetEntry(date: Date(), configuration: SmallWidgetConfigurationAppIntent(),models:[snapshotModel])
    }
    
    //通常のウィジェット
    func timeline(for configuration: SmallWidgetConfigurationAppIntent, in context: Context) async -> Timeline<SmallBalanceWidgetEntry> {
        var entries: [SmallBalanceWidgetEntry] = []
        
        let savedWidgetData = getSavedWidgetData()
        let selectCardIDm = configuration.card?.idm
        let selectCard = savedWidgetData.first(where: { $0.idm == selectCardIDm }) ?? snapshotModel
        
        let entryDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        entries = [SmallBalanceWidgetEntry(date: entryDate, configuration: configuration,models:[selectCard])]

        return Timeline(entries: entries, policy: .atEnd)
    }
    
}
