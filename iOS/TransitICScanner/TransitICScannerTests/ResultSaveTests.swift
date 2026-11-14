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
