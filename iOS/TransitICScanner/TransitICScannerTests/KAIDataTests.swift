import Foundation
import Testing

@testable import TransitICScanner

/// KAI Commuterのバイト解析を合成ブロックで確認する。実カードの記録は使わない。
struct KAIDataTests {
    private let idBlock = Data("1234567890123456".utf8)
    /// 残高・直前取引額はリトルエンディアン、取引通番（13〜15バイト目）はビッグエンディアン。
    private let balanceBlock = Data([0x78, 0x56, 0x34, 0x12, 1, 2, 3, 4, 0, 0, 0, 0, 0, 1, 2, 3])
    /// 金額・改札コード・通番はビッグエンディアン。12バイト目が取引種別。
    private let historyBlock = Data([0x30, 0, 0, 0, 0, 0, 0x12, 0x34, 0x56, 0x78, 0, 0, 1, 1, 2, 3])

    @Test func parsesBalanceBlock() throws {
        let parsed = try #require(
            KAIData.parse(idBlock: idBlock, balanceBlock: balanceBlock, historyBlocks: [historyBlock])
        )

        #expect(parsed.serialNumber == "1234567890123456")
        #expect(parsed.balance == 0x1234_5678)
        #expect(parsed.lastTransactionAmount == 0x0403_0201)
        #expect(parsed.transactionCounter == 0x01_0203)
    }

    @Test func parsesHistoryBlock() throws {
        let parsed = try #require(
            KAIData.parse(idBlock: idBlock, balanceBlock: balanceBlock, historyBlocks: [historyBlock])
        )
        let history = try #require(parsed.histories.first)

        #expect(history.balance == 0x1234)
        #expect(history.transactionId == 0x01_0203)
        #expect(history.lineOut == 0x56)
        #expect(history.stationOut == 0x78)
        #expect(history.date.year != nil)
    }

    @Test func slicedDataMatchesUnslicedInput() throws {
        let slicedBalance = (Data([0xFF]) + balanceBlock).dropFirst()
        let slicedHistory = (Data([0xFF]) + historyBlock).dropFirst()
        #expect(slicedBalance.startIndex != 0)

        let expected = KAIData.parse(idBlock: idBlock, balanceBlock: balanceBlock, historyBlocks: [historyBlock])
        let sliced = KAIData.parse(idBlock: idBlock, balanceBlock: slicedBalance, historyBlocks: [slicedHistory])

        #expect(sliced?.balance == expected?.balance)
        #expect(sliced?.histories == expected?.histories)
    }

    @Test func rejectsShortBlocks() {
        #expect(KAIData.parse(idBlock: Data(), balanceBlock: balanceBlock, historyBlocks: []) == nil)
        #expect(
            KAIData.parse(idBlock: idBlock, balanceBlock: Data(repeating: 0, count: 15), historyBlocks: []) == nil
        )
    }

    @Test func skipsMalformedOrEmptyHistories() throws {
        var noGate = historyBlock
        noGate[8] = 0
        noGate[9] = 0
        let parsed = try #require(
            KAIData.parse(
                idBlock: idBlock,
                balanceBlock: balanceBlock,
                historyBlocks: [Data(), Data(repeating: 0, count: 15), noGate, historyBlock]
            )
        )

        #expect(parsed.histories.count == 1)
    }

    @Test func nonChargeTransactionIsNegative() throws {
        var payment = historyBlock
        payment[12] = 255
        let parsed = try #require(
            KAIData.parse(idBlock: idBlock, balanceBlock: balanceBlock, historyBlocks: [payment])
        )

        #expect(parsed.histories.first?.balance == -0x1234)
    }
}
