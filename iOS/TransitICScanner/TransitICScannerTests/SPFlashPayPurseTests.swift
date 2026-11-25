import Foundation
import Testing

@testable import TransitICScanner

struct SPFlashPayPurseTests {
    @Test
    func parsesSignedBalancesAndSlicedData() {
        var bytes = makeResponse()
        bytes.replaceSubrange(2..<5, with: [0x00, 0x04, 0xD2])
        #expect(SPFlashPayPurse.parse(bytes)?.balanceCents == 1234)

        bytes.replaceSubrange(2..<5, with: [0xFF, 0xFF, 0x9C])
        let wrapped = Data([0xFF]) + bytes
        let purse = SPFlashPayPurse.parse(wrapped.dropFirst())
        #expect(purse?.balanceCents == -100)
        #expect(purse?.can == "1000000000000000")
    }

    @Test
    func rejectsShortResponsesAndOtherIssuers() {
        var bytes = makeResponse()
        #expect(SPFlashPayPurse.parse(Data()) == nil)
        #expect(SPFlashPayPurse.parse(bytes.dropLast()) == nil)

        bytes[8] = 0x11
        bytes[9] = 0x11
        #expect(SPFlashPayPurse.parse(bytes)?.isEZLink == false)

        bytes[8] = 0x10
        bytes[9] = 0x0A
        #expect(SPFlashPayPurse.parse(bytes) == nil)
    }

    @Test
    func parsesBalanceWithoutReadingTrailingIssuerData() {
        var bytes = makeResponse() + Data(repeating: 0, count: 18)
        bytes[41] = 32
        #expect(SPFlashPayPurse.parse(bytes)?.balanceCents == 0)
    }

    private func makeResponse() -> Data {
        var bytes = Data(repeating: 0, count: 62)
        bytes[8] = 0x10
        return bytes
    }
}
