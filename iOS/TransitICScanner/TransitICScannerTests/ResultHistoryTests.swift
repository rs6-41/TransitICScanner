import Foundation
import Testing

@testable import TransitICScanner

/// 保存時の重複判定に使う `transactionId` の生成規則を確認する。
struct ResultHistoryTests {
    private let date = DateComponents(year: 2026, month: 11, day: 14, hour: 9, minute: 30, second: 15)

    @Test func transactionIDIsDeterministic() {
        let first = ResultHistory.makeTransactionID(date: date, processType: 1, balance: 1000)
        let second = ResultHistory.makeTransactionID(date: date, processType: 1, balance: 1000)

        #expect(first == second)
    }

    @Test func transactionIDDistinguishesTransactions() {
        let base = ResultHistory.makeTransactionID(date: date, processType: 1, balance: 1000)
        var nextSecond = date
        nextSecond.second = 16

        #expect(base != ResultHistory.makeTransactionID(date: nextSecond, processType: 1, balance: 1000))
        #expect(base != ResultHistory.makeTransactionID(date: date, processType: 2, balance: 1000))
        #expect(base != ResultHistory.makeTransactionID(date: date, processType: 1, balance: 999))
    }

    @Test func transactionIDToleratesMissingComponents() {
        let empty = ResultHistory.makeTransactionID(date: DateComponents(), processType: 0, balance: 0)

        #expect(empty == 0)
    }
}
