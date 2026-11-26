import Foundation

nonisolated struct SPEZLinkPurse: Equatable {
    static let minimumResponseLength = 62

    let balanceCents: Int
    let can: String
    let logfileRecordCount: Int

    static func parse(_ data: Data) -> Self? {
        let bytes = Array(data)
        guard bytes.count >= minimumResponseLength else { return nil }

        let canBytes = bytes[8..<16]
        guard bytes[8] == 0x10, bytes[9] >> 4 == 0,
            canBytes.allSatisfy({ $0 >> 4 <= 9 && $0 & 0x0F <= 9 })
        else { return nil }

        let encodedBalance = Int(bytes[2]) << 16 | Int(bytes[3]) << 8 | Int(bytes[4])
        let balanceCents = encodedBalance >= 0x800000 ? encodedBalance - 0x1000000 : encodedBalance
        let can = canBytes.map { String(format: "%02X", $0) }.joined()
        return Self(balanceCents: balanceCents, can: can, logfileRecordCount: Int(bytes[40]))
    }
}
