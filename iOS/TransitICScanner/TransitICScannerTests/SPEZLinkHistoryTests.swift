import Foundation
import Testing

@testable import TransitICScanner

struct SPEZLinkHistoryTests {
    @Test
    func parsesSignedAmountsAndSingaporeTime() throws {
        let debit = Data([0x31, 0xFF, 0xFF, 0x9C, 0, 0, 0, 60] + Array(repeating: UInt8(0), count: 8))
        let credit = Data([0x75, 0, 0x04, 0xD2, 0, 0, 0, 60] + Array(repeating: UInt8(0), count: 8))
        let items = try #require(SPEZLinkHistory.parse(debit + credit))
        #expect(items.map(\.amount) == [-1, 12.34])
        #expect(items.map(\.processType) == [0x31, 0x75])
        #expect(items.first?.date.year == 1995)
        #expect(items.first?.date.hour == 0)
        #expect(items.first?.date.minute == 1)
        #expect(items.first?.transactionId == SPEZLinkHistory.parse(debit)?.first?.transactionId)
    }

    @Test
    func calculatesPostTransactionBalancesAcrossPages() throws {
        let debit = Data([0x31, 0xFF, 0xFF, 0x9C, 0, 0, 0, 120] + Array(repeating: UInt8(0), count: 8))
        let credit = Data([0x75, 0, 0x04, 0xD2, 0, 0, 0, 60] + Array(repeating: UInt8(0), count: 8))
        let oldest = Data([0x31, 0xFF, 0xFF, 0xFF, 0, 0, 0, 30] + Array(repeating: UInt8(0), count: 8))
        let items = try #require(SPEZLinkHistory.parse(credit + debit + debit + oldest))
        let results = try SPEZLinkHistory.calculatingBalances(items, currentBalanceCents: 1_134)
        #expect(results.map(\.balance) == [11.34, 12.34, 0])
        #expect(results.map(\.amount) == [-1, 12.34, -0.01])
        #expect(try SPEZLinkHistory.calculatingBalances([], currentBalanceCents: -1).isEmpty)
    }

    @Test
    func sortsSingaporeWallClockTimesAndRejectsInvalidDates() throws {
        let record = Data([0x31, 0xFF, 0xFF, 0x9C, 0, 0, 0, 60] + Array(repeating: UInt8(0), count: 8))
        var earlier = try #require(SPEZLinkHistory.parse(record)?.first)
        earlier.date = DateComponents(
            timeZone: TimeZone(identifier: "America/Los_Angeles"),
            year: 2026, month: 3, day: 8, hour: 2, minute: 30, second: 0
        )
        var later = earlier
        later.date.hour = 3
        later.date.minute = 0
        #expect(try SPEZLinkHistory.newestFirst([earlier, later]) == [later, earlier])

        earlier.date.day = 32
        #expect(throws: SPEZLinkHistory.HistoryError.invalidDate) {
            try SPEZLinkHistory.calculatingBalances([earlier], currentBalanceCents: 100)
        }
    }

    @Test
    func failsWhenRequiredSecondPageIsUnavailable() async {
        let page = Data(repeating: 1, count: 256)
        let failure = ReaderError.message("History read failed")
        for secondResponse in [(Data(), UInt8(0x6A), UInt8(0x80)), (Data(), 0x90, 0)] {
            await #expect(throws: ReaderError.self) {
                try await spEZLinkHistory(
                    using: { _, _, _, _, payload, _ in
                        payload.first == 0 ? (page, 0x90, 0) : secondResponse
                    },
                    logfileRecordCount: 32,
                    readError: failure
                )
            }
        }
    }

    @Test
    func keepsFlashPayAndEZLinkScanIdentifiersSeparate() {
        #expect(CardID(rawValue: "spFlashPay")?.rawValue == "spFlashPay")
        #expect(CardID(rawValue: "spEZLink")?.rawValue == "spEZLink")
    }

    @Test
    func rejectsMalformedPagesAndSkipsBlankRecords() {
        #expect(SPEZLinkHistory.parse(Data(repeating: 0, count: 15)) == nil)
        #expect(SPEZLinkHistory.parse(Data(repeating: 0, count: 272)) == nil)
        #expect(SPEZLinkHistory.parse(Data(repeating: 0, count: 16))?.isEmpty == true)
    }
}
