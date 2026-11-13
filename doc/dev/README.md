# 開発

 - [共通規定](../../AGENTS.md)：命名、互換性、作業・Gitの規定
 - [Apple実装規定](../../iOS/TransitICScanner/AGENTS.md)：責務、共有処理、ターゲット別検証
 - [カード定義規定](../../iOS/TransitICScanner/TransitICScanner/CardDefine/AGENTS.md)：カード実装の根拠・登録手順
 - [スキル・検証補助の規定](../../skills/AGENTS.md)：再利用手順とテスト
 - [工程別スキル](../../skills/README.md)：Issue作成、仕様書、iOS実装、翻訳補完
 - [ファイル構成とアーキテクチャ](./ARCHITECTURE.md)：各ファイルの役割・実装意図、よくある変更で触るファイル

## 開発環境
### iOS
 - macOS 27
 -- Xcode 27
 -- Swift 6.4（Xcode プロジェクトの言語モードは Swift 5 / `SWIFT_VERSION = 5.0`）

## コードの書式

Swift のコードは `swift-format`（Xcode 付属）で書式を揃える。設定は `iOS/TransitICScanner/.swift-format`（4スペースインデント、1行120文字）。

```sh
cd iOS/TransitICScanner
git ls-files -z '*.swift' | xargs -0 xcrun swift-format format --in-place --configuration .swift-format
```

## コミットメッセージ規定
絵文字 + Issues番号 + 内容
|絵文字|意味|
| -- | -- |
|📃|ドキュメントの更新|
|✨|新機能の追加|
|🐛|バグの修正|
|♻️|コードの整理|
|💄|UI・デザインの変更|
|⚡️|パフォーマンス改善|
|✅|テストの追加・修正|

### Commitizen

コミットメッセージを対話形式で作成するには、最初にプロジェクトの依存関係をインストールします。

```sh
npm ci
git config --local alias.cz '!npx --no-install cz'
```

以降は `git cz` を実行し、変更内容の絵文字を選択してIssue番号と内容を入力します。たとえば Issue番号に `107`、内容に `README.mdに英訳を追加` を入力すると、`📃 #107 README.mdに英訳を追加` がコミットメッセージになります。

Codexが作業した場合は、Issue本文とコミットの内容に `Codex` と明記し、作業の出所を記録します。

## 整理・検証

リポジトリのルートで実行します。

```sh
# 命名規則を検証（保存・外部契約に必要な例外は共通規定を参照）
python3 skills/transit-card-workflow/scripts/check_naming.py

# 追跡中のSwiftファイルの書式を検証
git ls-files -z '*.swift' | xargs -0 xcrun swift-format lint --strict --configuration iOS/TransitICScanner/.swift-format

# KAI Commuterの解析・読み取り処理の回帰テスト（macOS / Swiftが必要）
python3 skills/transit-card-workflow/scripts/test_idkai.py
python3 skills/transit-card-workflow/scripts/test_idkai_identity.py

# Widget保存データの旧JSONキーとの互換性を検証
python3 skills/transit-card-workflow/scripts/test_widget_compatibility.py

# 翻訳チェック用ツールの回帰テスト
python3 skills/transit-localization/scripts/test_check_xcstrings.py

# ユニットテスト（TransitICScannerTests、Devスキーム）
# CIと同じくチーム不要のアドホック署名でApp Groupのentitlementを付ける
xcodebuild test -project iOS/TransitICScanner/TransitICScanner.xcodeproj -scheme Dev \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= PROVISIONING_PROFILE_SPECIFIER=

# 空白エラーと作業ツリーの確認
git diff --check
git status --short
```

末尾に ` 2` が付いたファイルなど、同期・コピー時に生じた重複は、元ファイルとの内容一致と参照の有無を確認してから削除します。画像や設定ファイルでは名前だけで判断しないでください。

ビルド対象の選び方は[Apple実装規定](../../iOS/TransitICScanner/AGENTS.md)を参照してください。ファイルの追加・改名後はステージしてから `git ls-files` を使うと、新しいファイルもformat/lintの対象になります。

## CI/CD

| 仕組み | 契機 | 内容 | 設定 |
|---|---|---|---|
| GitHub Actions | PR、mainへのpush、手動 | 命名・書式・空白チェック、Python回帰テスト、`Dev` のユニットテスト、`Widget` / `Watch_Dev` のビルド | `.github/workflows/ci.yml`（ランナー `xcode-27`） |
| Xcode Cloud | App Store Connectのワークフローで設定 | Archive・TestFlight配布（必要に応じて `Dev` のTest） | `iOS/TransitICScanner/ci_scripts/` |

### Xcode Cloud の設定

ワークフロー自体はリポジトリではなくXcode（Report navigator → Cloud）またはApp Store Connectで作成します。

1. 環境変数にシークレットとして `ADMOB_NATIVE_UNIT_ID` と `ADMOB_BANNER_UNIT_ID` を登録する（値はログに出力しない）。
2. 配布用ワークフローは `Release`（または `Beta`）スキームのArchiveアクションと、TestFlight/App Storeへの配布ポストアクションを設定する。
3. テストを実行する場合は `Dev` スキームのTestアクションを追加する。

`ci_scripts/` の各スクリプトの役割：

- `ci_post_clone.sh`：`env.swift` を生成する。Archiveでは広告ユニットIDの未設定をエラーにする。
- `ci_post_xcodebuild.sh`：Archive成功時に直近10コミットから `TestFlight/WhatToTest.*.txt`（TestFlightの「テスト内容」）を生成する。生成物はコミットしない。
- `make_env_swift.sh`：`env.swift` の生成本体。GitHub Actionsからも使う。既存の `env.swift` があり環境変数が未設定なら上書きしない。
