import Foundation
import os

/// アプリ共通のロガー
///
/// - `Log.debug`: 開発時の詳細ログ。DEBUG ビルドでのみ出力し、カード IDm などの値を含み得るため
///   メッセージは `.private` として記録する（Xcode のデバッガ接続時以外は伏せ字になる）。
/// - `Log.error`: リリースビルドでも記録するエラー。個人情報やカードの識別子を含めないこと。
enum Log {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.rs6apps.TransitICScanner"

    /// 開発時の詳細ログ（`print` の置き換え）。カテゴリは呼び出し元のファイル名。
    static func debug(_ items: Any..., separator: String = " ", fileID: String = #fileID) {
        #if DEBUG
        let message = items.map { "\($0)" }.joined(separator: separator)
        logger(fileID).debug("\(message, privacy: .private)")
        #endif
    }

    /// リリースビルドでも記録するエラーログ
    static func error(_ message: String, fileID: String = #fileID) {
        logger(fileID).error("\(message, privacy: .public)")
    }

    private static func logger(_ fileID: String) -> Logger {
        let category =
            fileID
            .split(separator: "/")
            .last
            .map { String($0.replacingOccurrences(of: ".swift", with: "")) }
            ?? "App"
        return Logger(subsystem: subsystem, category: category)
    }
}
