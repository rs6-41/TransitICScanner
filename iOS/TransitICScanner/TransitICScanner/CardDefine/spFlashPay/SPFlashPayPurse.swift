import Foundation

nonisolated struct SPFlashPayPurse: Equatable {
    let balanceCents: Int
    let can: String

    let isEZLink: Bool

    static func parse(_ data: Data) -> Self? {
        let bytes = Array(data)
        guard bytes.count >= 62 else { return nil }

        let canBytes = bytes[8..<16]
        let isEZLink = bytes[8] == 0x10 && bytes[9] >> 4 == 0
        let isFlashPay = bytes[8] == 0x11 && bytes[9] == 0x11
        guard isEZLink || isFlashPay,
            canBytes.allSatisfy({ $0 >> 4 <= 9 && $0 & 0x0F <= 9 })
        else { return nil }

        let encodedBalance = Int(bytes[2]) << 16 | Int(bytes[3]) << 8 | Int(bytes[4])
        let balanceCents = encodedBalance >= 0x800000 ? encodedBalance - 0x1000000 : encodedBalance
        let can = canBytes.map { String(format: "%02X", $0) }.joined()
        return Self(balanceCents: balanceCents, can: can, isEZLink: isEZLink)
    }
}
