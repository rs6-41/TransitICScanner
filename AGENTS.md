# リポジトリ共通規定

このファイルはリポジトリ全体に適用する。サブディレクトリのAGENTS.mdは担当領域の追加規則を定め、共通規則を複製しない。

## 規定と資料の役割

- 命名・変更手順・互換性・検証の共通規定はこのファイルを正とする。
- Appleプラットフォームの実装は `iOS/TransitICScanner/AGENTS.md`、カード定義はその配下の `TransitICScanner/CardDefine/AGENTS.md`、補助スクリプトは `script/AGENTS.md` に従う。
- `doc/dev/ARCHITECTURE.md` は構成と責務、`doc/dev/README.md` は環境と実行手順、`doc/cards/` はカード仕様の根拠を記載する。規定の変更はAGENTS.md、構成の変更はARCHITECTURE.mdに反映する。

## 命名と書式

- Swiftの型・protocol・typealiasは `UpperCamelCase`、変数・定数・プロパティ・関数・引数・enum caseは `lowerCamelCase` とする。関数の名前空間をアンダースコアで区切らない。
- 頭字語は型名の途中・末尾では `ID` / `URL` / `NFC` / `APDU` のように大文字を保ち、先頭では `id` / `url` / `nfc` / `apdu` とする。CoreNFCの `IDm` など外部APIの綴りはその契約に従う。
- Boolは `is` / `has` / `can` / `should` / `shows` など、真偽を読み取れる名前にする。コレクションには `cards` / `records` / `models` のような複数形を使う。
- 値が変わらないものは `let` を使う。意味のある処理に `data1` / `temp` などの曖昧な名前を使わず、短い添字やバイト解析の局所変数は用途が明らかな範囲に限る。
- Swiftファイル名は主となる型名、または `Localization.swift` のような機能名を使う。カード定義ファイル・フォルダはカードID、分割extensionは `<カードID>+<責務>.swift` を使う。
- 書式は `iOS/TransitICScanner/.swift-format` を正とする。Swiftは4スペース・120文字幅、Pythonは4スペース・snake_case、JavaScriptは既存Commitizenアダプターの2スペース・camelCaseに揃える。
- コメントは処理の根拠・制約・単位を説明する。仕様値や動作を命名整理と同時に変更しない。

## 互換性を伴う名前の例外

- `CardID` / `ConverterType` の既存case・rawValue、カード定義の定数（`jpIC_SAPICA` 等）・ディレクトリ名、Asset名、ローカライズキーは共通識別子として維持する。
- SwiftDataの `@Model` 型名・保存プロパティ名、既存Codableのキー、App Group / CloudKit / UserDefaultsのキー、Bundle ID、App Intentの識別子は保存・外部契約である。書式統一だけを理由に変更しない。
- 例：保存モデルの `transactionId` / `idm`、WidgetのJSONキー `DisplayName` / `widgetDatas` は既存契約。Swift側だけを改名する場合は明示的な `CodingKeys` と旧データのdecode・再encodeテストを追加する。SwiftDataはマイグレーション計画を別途用意する。
- 非追跡の `env.swift` が提供する `bannerUnitID` / `NativeUnitID` は外部設定との境界として維持する。内容をコミット・ログ出力しない。
- Issue #118でKAI Commuterの現行識別子は `idKAI` に統一した。旧 `idKMT` のID・ローカライズキー・画像名は `Utility/CardIdentity.swift` で読み込み時に解決する。旧文字列はこの互換処理と回帰テスト・説明に限定し、新規データには現行名を使う。
- 新しい例外は必要な互換性を説明し、命名チェックの許可対象は該当ファイル・識別子だけに限定する。

## 作業・検証・Git

1. 開始時に `git status` と適用対象のAGENTS.mdを確認する。既存のユーザー変更は上書きしない。
2. 改名時は宣言だけでなく、呼び出し元・共有ターゲット・テストのソース抽出・Xcodeのファイル参照・開発文書も検索する。文字列キーを一括置換しない。
3. コミット前に `python3 script/check_naming.py`、Swiftのformat/lint、`git diff --check` を実行する。動作を変更する場合は該当する回帰テストを実行する。実行コマンドは `doc/dev/README.md` に記載する。
4. 検証は実行した範囲と結果を正確に報告する。未実施のビルド・シミュレータ・実カード確認を成功扱いにしない。
5. 原則として `codex/` の作業用ブランチで変更し、依頼元ブランチへ直接pushしない。ユーザーが指定したブランチ・差し戻し手順を優先する。
6. コミットは `git cz` で「絵文字 + #Issue番号 + 内容」に揃える。Codexによる作業はIssueとコミット内容に `Codex` を明記する。push先を確認し、force pushはしない。
