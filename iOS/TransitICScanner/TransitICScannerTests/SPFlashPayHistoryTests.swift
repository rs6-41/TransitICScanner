import Foundation
import Testing

@testable import TransitICScanner

struct SPFlashPayHistoryTests {
    @Test
    func parsesSignedAmountsAndSingaporeTime() throws {
        let debit = Data([0x31, 0xFF, 0xFF, 0x9C, 0, 0, 0, 60] + Array(repeating: UInt8(0), count: 8))
        let credit = Data([0x75, 0, 0x04, 0xD2, 0, 0, 0, 60] + Array(repeating: UInt8(0), count: 8))
        let items = try #require(SPFlashPayHistory.parse(debit + credit))
        #expect(items.map(\.amount) == [-1, 12.34])
        #expect(items.map(\.processType) == [0x31, 0x75])
        #expect(items.first?.date.year == 1995)
        #expect(items.first?.date.hour == 0)
        #expect(items.first?.date.minute == 1)
        #expect(items.first?.transactionId == SPFlashPayHistory.parse(debit)?.first?.transactionId)
    }

    @Test
    func calculatesPostTransactionBalancesAcrossPages() throws {
        let debit = Data([0x31, 0xFF, 0xFF, 0x9C, 0, 0, 0, 120] + Array(repeating: UInt8(0), count: 8))
        let credit = Data([0x75, 0, 0x04, 0xD2, 0, 0, 0, 60] + Array(repeating: UInt8(0), count: 8))
        let oldest = Data([0x31, 0xFF, 0xFF, 0xFF, 0, 0, 0, 30] + Array(repeating: UInt8(0), count: 8))
        let items = try #require(SPFlashPayHistory.parse(credit + debit + debit + oldest))
        let results = SPFlashPayHistory.calculatingBalances(items, currentBalanceCents: 1_134)
        #expect(results.map(\.balance) == [11.34, 12.34, 0])
        #expect(results.map(\.amount) == [-1, 12.34, -0.01])
        #expect(SPFlashPayHistory.calculatingBalances([], currentBalanceCents: -1).isEmpty)
    }

    @Test
    func rejectsMalformedPagesAndSkipsBlankRecords() {
        #expect(SPFlashPayHistory.parse(Data(repeating: 0, count: 15)) == nil)
        #expect(SPFlashPayHistory.parse(Data(repeating: 0, count: 272)) == nil)
        #expect(SPFlashPayHistory.parse(Data(repeating: 0, count: 16))?.isEmpty == true)
    }
}
