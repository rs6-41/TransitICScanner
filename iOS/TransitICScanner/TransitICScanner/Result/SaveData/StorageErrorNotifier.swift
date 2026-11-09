import SwiftUI
import Combine

/// 保存・削除の失敗をユーザーに通知する
///
/// 結果画面は閉じるときに保存するため、失敗した時点で画面が残っていないことがある。
/// そのため通知はアプリのルート(ContentView)でまとめて表示する。
@MainActor
final class StorageErrorNotifier: ObservableObject {
    static let shared = StorageErrorNotifier()

    @Published var isPresented = false
    @Published private(set) var message = ""

    private init() {}

    func report(_ error: any Error, operation: String) {
        Log.error("\(operation)に失敗: \(error.localizedDescription)")
        message = error.localizedDescription
        isPresented = true
    }
}
