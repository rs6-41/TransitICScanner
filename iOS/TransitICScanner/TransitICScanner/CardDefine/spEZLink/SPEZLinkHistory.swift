import CryptoKit
import Foundation

enum SPEZLinkHistory {
    static let balanceMappingID = "cepasBalance"

    static func newestFirst(_ history: [ResultHistory]) -> [ResultHistory] {
        let calendar = Calendar(identifier: .gregorian)
        return history.sorted {
            (calendar.date(from: $0.date) ?? .distantPast) > (calendar.date(from: $1.date) ?? .distantPast)
        }
    }

    static func calculatingBalances(_ history: [ResultHistory], currentBalanceCents: Int) -> [ResultHistory] {
        var balanceCents = currentBalanceCents
        var seen = Set<Int>()
        return newestFirst(history).compactMap { item in
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

        var calendar = Calendar(identifier: .gregorian)
        if let singapore = TimeZone(identifier: "Asia/Singapore") {
            calendar.timeZone = singapore
        }
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
