import Foundation
import Testing

@testable import TransitICScanner

/// 残高表示は小数点以下を最大2桁まで表示し、整数値では小数部を省略する。
struct BalanceFormatTests {
    @Test(arguments: [(0.0, "0"), (100.0, "100"), (12.5, "12.5"), (0.25, "0.25")])
    func formatsBalance(value: Double, expected: String) {
        // 小数点記号はロケールに依存するため、比較前に "." へ揃える。
        let text = value.balanceText.replacingOccurrences(of: ",", with: ".")
        #expect(text == expected)
    }
}
