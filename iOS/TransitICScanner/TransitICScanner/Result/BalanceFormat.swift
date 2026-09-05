import Foundation

extension Double {
    private static let balanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.minimumIntegerDigits = 1
        return formatter
    }()

    var balanceText: String {
        Self.balanceFormatter.string(from: NSNumber(value: self)) ?? "0"
    }
}
