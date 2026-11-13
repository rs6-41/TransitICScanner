# Appleプラットフォームの実装規定

ルートの `AGENTS.md` を継承し、アプリ本体・Widget・Watch・テンプレートに適用する。

## 責務と共有実装

- 型は `Scan/CardModel.swift`、`Result/ResultModel.swift`、保存は `Result/SaveData/ResultSave.swift`、環境は `Storage.swift`、Widget用データは `CardBalanceWidget/BalanceWidgetModel.swift` の既存契約を使う。同じ用途のモデル・保存先・変換処理を追加しない。
- Viewは表示と入力を担当し、カードの通信・バイト解析を持たせない。UI状態更新はMainActorで行い、既存の `@StateObject` / `@ObservedObject` / `@EnvironmentObject` の所有関係を維持する。命名整理にObservation方式の変更を混ぜない。
- 保存・削除は `ResultSave` を通す。新規スキャンの保存と保存済みカードのユーザー編集を区別し、表示名の編集で残高・履歴を上書きしない。
- Widgetは `WidgetDataStore` 経由のApp Groupデータを読み、保存更新後にタイムラインを更新する。Watchの共有モデルとCloudKit同期に影響する変更では両ターゲットを検証する。
- FeliCaは `FeliCaTagReading`、ISO 7816は `APDUSend` を通じて内蔵・外部リーダーで解析を共有する。カードごとの追加規則は `TransitICScanner/CardDefine/AGENTS.md` を参照する。

## エラー・表示・プライバシー

- データ長・整数変換・配列添字を検証し、読取失敗を正常なゼロ残高で代用しない。継続処理は全経路で一度だけ完了させる。
- 表示文字列は既存文字列カタログのキーを使う。変数用の翻訳は `localizedString(_:)` に集約し、表示用のキーやAssetを改名だけで作り直さない。
- アプリのログは `Log.debug` / `Log.error` を使う。IDm・カード番号・利用履歴・秘密設定を公開ログに出さない。
- 広告は `AdConsentManager.shared.canRequestAds` に従う。環境分岐は `AppEnvironment` / `StorageConfig` を使う。
- 実装内部の状態・補助関数は可能な範囲で `private` にする。共有ターゲットから使う型・メンバーの可視性は維持する。

## ファイル登録と検証

- Xcodeの同期グループを使っている。追加・改名時は `project.pbxproj` のmembershipExceptionsとplatformFiltersByRelativePathを確認する。特にWatch・Widgetで共有するファイルの登録を落とさない。
- アプリの改名・共通処理変更は `Dev`、Watch共有部分は `Watch_Dev`、Widget共有部分は `Widget`、環境分岐・リリース側を触った場合は `Release` をビルドする。結果をターゲットごとに記録する。
- 命名のみの変更では、カードのサービスコード・ブロック数・バイト位置・日時・残高・取引分類・履歴順が不変であることを差分で確認する。
- Widgetの保存契約を触ったら `python3 script/tests/test_widget_compatibility.py`、KMT読取処理を触ったら `python3 script/tests/test_idkai.py` を実行する。
- `CardBalance/` はビルド対象外のテンプレート。アプリの実装と取り違えず、ここだけの検証でアプリのビルド確認を代替しない。
