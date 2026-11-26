import Foundation
import SwiftData
import Testing

@testable import TransitICScanner

@MainActor
struct ResultSaveTests {
    @Test func rescanningUpdatesOnlyTheMatchingCard() throws {
        let container = try ModelContainer(
            for: SavedCard.self, SavedHistory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let context = container.mainContext
        let first = makeResult(idm: "SYNTHETIC-CARD-A", balance: 100)
        let other = makeResult(idm: "SYNTHETIC-CARD-B", balance: 200)
        try ResultSave.save(first, in: context)
        try ResultSave.save(other, in: context)
        try ResultSave.save(makeResult(idm: "SYNTHETIC-CARD-A", balance: 300), in: context)

        let cards = try context.fetch(FetchDescriptor<SavedCard>())
        #expect(cards.count == 2)
        #expect(cards.first { $0.idm == "SYNTHETIC-CARD-A" }?.balance == 300)
        #expect(cards.first { $0.idm == "SYNTHETIC-CARD-B" }?.balance == 200)
    }

    @Test func ezLinkKeepsResponseOrderAfterRescanningAndReloading() throws {
        let container = try ModelContainer(
            for: SavedCard.self, SavedHistory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let date = DateComponents(year: 2026, month: 11, day: 26, hour: 12, minute: 0, second: 0)
        let first = ResultHistory(
            date: date, balance: 0, amount: -1, lineIn: 0, stationIn: 0, lineOut: 0, stationOut: 0,
            transactionId: 20
        )
        var second = first
        second.transactionId = 10
        second.amount = -2

        var result = makeResult(idm: "SYNTHETIC-EZ-LINK", balance: 10)
        result.converter = .spEZLink
        result.isHistory = true
        result.history = [second, first]
        try ResultSave.save(result, in: container.mainContext)

        result.history = try SPEZLinkHistory.calculatingBalances([first, second], currentBalanceCents: 1_000)
        try ResultSave.save(result, in: container.mainContext)

        let reloaded = ModelContext(container)
        let saved = try #require(reloaded.fetch(FetchDescriptor<SavedCard>()).first)
        let records = try #require(saved.result().history)
        let restored = try SPEZLinkHistory.newestFirst(records.sorted { $0.transactionId < $1.transactionId })
        #expect(restored.map(\.transactionId) == [20, 10])
        #expect(restored.map(\.responseOrder) == [0, 1])
        #expect(restored.map(\.balance) == [10, 11])

        var newest = first
        newest.transactionId = 30
        result.balance = 9
        result.history = try SPEZLinkHistory.calculatingBalances([newest, first], currentBalanceCents: 900)
        try ResultSave.save(result, in: container.mainContext)

        let afterPartialScan = ModelContext(container)
        let updatedCard = try #require(afterPartialScan.fetch(FetchDescriptor<SavedCard>()).first)
        let updatedRecords = try #require(updatedCard.result().history)
        let updated = try SPEZLinkHistory.newestFirst(updatedRecords.sorted { $0.transactionId < $1.transactionId })
        #expect(updated.map(\.transactionId) == [30, 20, 10])
        #expect(updated.map(\.responseOrder) == [0, 1, 2])
        #expect(updated.map(\.balance) == [9, 10, 11])
    }

    private func makeResult(idm: String, balance: Double) -> ScanResult {
        ScanResult(
            balance: balance,
            isHistory: false,
            history: nil,
            info: ResultCardInfo(
                idm: idm, name: "cardList.jpIC", nameShort: "jpIC.short",
                displayName: "Fixture card", iconName: nil, currencyType: .jpy, type: "",
                serial: nil, version: nil, validDate: nil, issueInfo: nil
            ),
            converter: .jpIC,
            isLastHide: false,
            description: ""
        )
    }
}
