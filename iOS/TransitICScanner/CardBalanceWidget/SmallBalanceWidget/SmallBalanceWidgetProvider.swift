import SwiftUI
import WidgetKit

struct SmallBalanceWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: SmallWidgetConfigurationAppIntent

    let model: BalanceWidgetModel
}

struct SmallBalanceWidgetProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> SmallBalanceWidgetEntry {
        SmallBalanceWidgetEntry(
            date: Date(), configuration: SmallWidgetConfigurationAppIntent(), model: placeholderWidgetModel)
    }

    func snapshot(
        for configuration: SmallWidgetConfigurationAppIntent, in context: Context
    ) async -> SmallBalanceWidgetEntry {
        SmallBalanceWidgetEntry(
            date: Date(), configuration: SmallWidgetConfigurationAppIntent(), model: placeholderWidgetModel)
    }

    //通常のウィジェット
    func timeline(
        for configuration: SmallWidgetConfigurationAppIntent, in context: Context
    ) async -> Timeline<SmallBalanceWidgetEntry> {
        var entries: [SmallBalanceWidgetEntry] = []

        let savedWidgetData = getSavedWidgetData()
        let selectedCardIDm = configuration.card?.idm
        let selectedCard = savedWidgetData.first(where: { $0.idm == selectedCardIDm }) ?? placeholderWidgetModel

        let entryDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        entries = [SmallBalanceWidgetEntry(date: entryDate, configuration: configuration, model: selectedCard)]

        return Timeline(entries: entries, policy: .atEnd)
    }

}
