import SwiftUI
import WidgetKit

struct ListBalanceWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: ListWidgetConfigurationAppIntent
    
    let models: [BalanceWidgetModel]
}

struct ListBalanceWidgetProvider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> ListBalanceWidgetEntry {
        ListBalanceWidgetEntry(date: Date(), configuration: ListWidgetConfigurationAppIntent(),models:[placeholderModel])
    }

    func snapshot(for configuration: ListWidgetConfigurationAppIntent, in context: Context) async -> ListBalanceWidgetEntry {
        ListBalanceWidgetEntry(date: Date(), configuration: ListWidgetConfigurationAppIntent(),models:[snapshotModel])
    }
    
    //通常のウィジェット
    func timeline(for configuration: ListWidgetConfigurationAppIntent, in context: Context) async -> Timeline<ListBalanceWidgetEntry> {
        var entries: [ListBalanceWidgetEntry] = []
        
        let savedWidgetData = getSavedWidgetData()
        
        var models:[BalanceWidgetModel] = []
        if let cards = configuration.card {
            for card in cards {
                let selectCardIDm = card.idm
                let selectCard = savedWidgetData.first(where: { $0.idm == selectCardIDm }) ?? snapshotModel
                models.append(selectCard)
            }
        }
        
        let entryDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        entries = [ListBalanceWidgetEntry(date: entryDate, configuration: configuration,models:models)]

        return Timeline(entries: entries, policy: .atEnd)
    }
    
}
