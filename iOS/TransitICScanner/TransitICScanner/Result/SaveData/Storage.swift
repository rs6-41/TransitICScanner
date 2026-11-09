import Foundation

/// ビルド構成（xcconfig の `APP_ENVIRONMENT` → Info.plist の `AppEnvironment`）
enum AppEnvironment: String {
    case dev = "DEV"
    case beta = "BETA"
    case rel = "REL"

    /// Info.plist に値がない場合（Widget など）はリリース扱い
    static let current: AppEnvironment = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "AppEnvironment") as? String
        return raw.flatMap(AppEnvironment.init(rawValue:)) ?? .rel
    }()
}

/// 保存先（App Group / CloudKit コンテナ）の設定
///
/// 保存先はプロセス起動時に一度だけ決定する。
/// 起動中に切り替えると、作成済みの ModelContainer と Widget 用データの参照先が食い違うため、
/// デバッグ用ストレージの切り替えは次回起動時から有効になる。
enum StorageConfig {
    static let releaseAppGroup = "group.com.rs6apps.TransitICScanner"
    static let debugAppGroup = "group.com.rs6apps.TransitICScanner.debug"

    static let releaseCloudKitContainer = "iCloud.com.rs6apps.TransitICScanner"
    static let debugCloudKitContainer = "iCloud.com.rs6apps.TransitICScanner.debug"

    static let debugStorageKey = "isDebugStorage"

    /// アプリと Widget で共有する設定。保存先の切り替えに依存しないよう常にリリース用 App Group を使う。
    static var sharedSettings: UserDefaults? {
        UserDefaults(suiteName: releaseAppGroup)
    }

    /// 起動時点のデバッグ用ストレージ設定
    static let isDebugStorage: Bool = sharedSettings?.bool(forKey: debugStorageKey) ?? false

    static var appGroup: String {
        isDebugStorage ? debugAppGroup : releaseAppGroup
    }

    static var cloudKitContainerIdentifier: String {
        isDebugStorage ? debugCloudKitContainer : releaseCloudKitContainer
    }

    /// デバッグ用ストレージの使用を設定する（次回起動時から有効）
    static func setDebugStorage(_ enabled: Bool) {
        sharedSettings?.set(enabled, forKey: debugStorageKey)
    }
}
