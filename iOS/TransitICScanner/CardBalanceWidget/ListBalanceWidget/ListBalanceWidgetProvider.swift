import SwiftUI
import WidgetKit

struct ListBalanceWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: ListWidgetConfigurationAppIntent
    
    let models: [BalanceWidgetModel]
    let updateDate: Date
}

struct ListBalanceWidgetProvider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> ListBalanceWidgetEntry {
        ListBalanceWidgetEntry(date: Date(), configuration: ListWidgetConfigurationAppIntent(),models:[placeholderModel],updateDate:Date.now)
    }

    func snapshot(for configuration: ListWidgetConfigurationAppIntent, in context: Context) async -> ListBalanceWidgetEntry {
        ListBalanceWidgetEntry(date: Date(), configuration: ListWidgetConfigurationAppIntent(),models:[placeholderModel],updateDate:Date.now)
    }
    
    //通常のウィジェット
    func timeline(for configuration: ListWidgetConfigurationAppIntent, in context: Context) async -> Timeline<ListBalanceWidgetEntry> {
        var entries: [ListBalanceWidgetEntry] = []
        
        let savedWidgetData = getSavedWidgetData()
        
        var models:[BalanceWidgetModel] = []
        if let cards = configuration.card {
            for card in cards {
                let selectCardIDm = card.idm
                let selectCard = savedWidgetData.first(where: { $0.idm == selectCardIDm }) ?? placeholderModel
                models.append(selectCard)
            }
        }
        
        let entryDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        entries = [ListBalanceWidgetEntry(date: entryDate, configuration: configuration,models:models, updateDate: Date.now)]

        return Timeline(entries: entries, policy: .atEnd)
    }
    
}
