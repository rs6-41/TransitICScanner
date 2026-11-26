import CryptoKit
import Foundation

enum SPEZLinkHistory {
    static let balanceMappingID = "cepasBalance"

    enum HistoryError: Error {
        case invalidDate
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Singapore") ?? TimeZone(secondsFromGMT: 8 * 3600)!
        return calendar
    }

    static func newestFirst(_ history: [ResultHistory]) throws -> [ResultHistory] {
        let calendar = calendar
        let dated = try history.map { item in
            var components = item.date
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            guard components.isValidDate(in: calendar), let date = calendar.date(from: components) else {
                throw HistoryError.invalidDate
            }
            return (item: item, date: date)
        }
        return dated.sorted { $0.date > $1.date }.map(\.item)
    }

    static func calculatingBalances(_ history: [ResultHistory], currentBalanceCents: Int) throws -> [ResultHistory] {
        var balanceCents = currentBalanceCents
        var seen = Set<Int>()
        return try newestFirst(history).compactMap { item in
            guard let amount = item.amount, seen.insert(item.transactionId).inserted else { return nil }
            var updated = item
            updated.balance = Double(balanceCents) / 100
            updated.mappingID = balanceMappingID
            balanceCents -= Int((amount * 100).rounded())
            return updated
        }
    }

    static func parse(_ data: Data) -> [ResultHistory]? {
        let bytes = Array(data)
        guard bytes.count <= 256, bytes.count.isMultiple(of: 16) else { return nil }

        let calendar = calendar
        let epoch = Date(timeIntervalSince1970: 788_889_600)

        return stride(from: 0, to: bytes.count, by: 16).compactMap { offset in
            let record = bytes[offset..<(offset + 16)]
            guard !record.allSatisfy({ $0 == 0 }) else { return nil }
            let rawAmount = record.dropFirst().prefix(3).reduce(0) { ($0 << 8) | Int($1) }
            let cents = rawAmount >= 0x800000 ? rawAmount - 0x1000000 : rawAmount
            let seconds = record.dropFirst(4).prefix(4).reduce(0) { ($0 << 8) | Int($1) }
            let date = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: epoch.addingTimeInterval(TimeInterval(seconds))
            )
            let id = SHA256.hash(data: Data(record)).prefix(8).reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
            let amount = Double(cents) / 100
            return ResultHistory(
                processType: bytes[offset], date: date, balance: amount, amount: amount,
                lineIn: 0, stationIn: 0, lineOut: 0, stationOut: 0,
                transactionId: Int(truncatingIfNeeded: id)
            )
        }
    }
}
