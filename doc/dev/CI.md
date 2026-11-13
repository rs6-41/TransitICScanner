# CI/CD の設計メモ

GitHub Actions と Xcode Cloud を使った CI/CD の構成について、それぞれの実装の意図と、レビューで直した点を記録します。手順（コマンド・設定方法）は [開発手順](./README.md#cicd) を参照してください。

- 導入：Issue #132（PR #133、#134、およびレビュー修正のPR）
- 作業：Claude Code（Anthropic Claude Opus 5.5）

---

## 1. 役割分担

| 仕組み | 担当 | 理由 |
|---|---|---|
| GitHub Actions | PRごとの検証（命名・書式・回帰テスト・ユニットテスト・Widget/Watchのビルド） | PRの画面で結果を確認でき、リポジトリ内のYAMLでレビューできる。署名や配布の権限が不要 |
| Xcode Cloud | Archive・TestFlight配布（必要に応じてテスト） | Appleの証明書・プロファイルをクラウド側で管理でき、秘密鍵をGitHubに置かずに済む |

GitHub Actions は検証だけを行い、署名用の証明書やApp Store ConnectのAPIキーを持たせません。配布に必要な秘密情報は Xcode Cloud の環境変数（シークレット）だけに置きます。

---

## 2. ユニットテストターゲット（`TransitICScannerTests`）

- **目的**：Xcode Cloud のテストアクションや `xcodebuild test` で実行できるテストがなかったため追加した。これまでの Python スクリプトの回帰テスト（本番ソースの一部を `swiftc` でコンパイルする方式）は残し、両方をCIで実行する。
- **Swift Testing + ホストアプリ**：アプリ本体の型を `@testable import TransitICScanner` で直接使うため、テストバンドルのホストをアプリにした（`TEST_HOST` / `BUNDLE_LOADER`）。本番ソースを抽出・複製しないので、改名・移動にも追従しやすい。
- **対象**：UIや実機NFCに依存しない処理だけを選んだ。
  - `CardIdentityTests`：旧識別子 `idKMT` → `idKAI` の互換処理（Issue #118）
  - `BalanceWidgetModelTests`：Widget用JSONの既存キー（`DisplayName` 等）の読み書き。保存契約が崩れると既存ユーザーのWidgetが空になるため
  - `KAIDataTests`：KAIカードのバイト解析（エンディアン、スライスの開始添字、短いブロックの拒否）
  - `ResultHistoryTests`：保存時の重複判定に使う `transactionId` が決定的で、別取引と衝突しにくいこと
  - `BalanceFormatTests`：残高表示の小数桁
- **データ**：すべて合成データで、実カードの記録や秘密設定は使わない（[Apple実装規定](../../iOS/TransitICScanner/AGENTS.md)）。
- **設定の意図**：アプリと同じく `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` と Swift 5 モードにそろえ、アプリの型をそのまま呼べるようにした。Mac Catalyst は対象外（`SUPPORTS_MACCATALYST = NO`）。テストは `Dev` スキームのTestアクションに登録した。

---

## 3. GitHub Actions（`.github/workflows/ci.yml`）

### ジョブ構成
| ジョブ | 内容 | 意図 |
|---|---|---|
| 命名・書式・回帰テスト | `check_naming.py`、`swift-format lint --strict`、`git diff --check`、Python回帰テスト | AGENTS.md のコミット前チェックを自動化する |
| ユニットテスト（Dev） | `xcodebuild test`（iOS シミュレータ） | ロジックの回帰を検出する。失敗時だけ xcresult を7日間保存する |
| ビルド（Widget / Watch_Dev） | `xcodebuild build` | 共有ファイル（`Storage.swift`、`ResultModel.swift` 等）の変更で、他ターゲットのビルドが壊れていないかを見る |

### 判断と理由
- **ランナー `xcode-27`**：プロジェクトが Xcode 27（`objectVersion = 90`）を前提としており、`macos-26` イメージには Xcode 27 がないため。
- **アドホック署名（`CODE_SIGN_IDENTITY=-` など）**：`CODE_SIGNING_ALLOWED=NO` で署名をしないと App Group の entitlement が付かない。その状態では `SavedDataModelContainer.makeContainer` で SwiftData が起動時に停止し、テストホストが落ちた。アドホック署名ならチームやプロファイルなしでシミュレータ向けに entitlement を埋め込める。
- **`env.swift` のダミー生成**：`env.swift` は Git 管理外のためクローン直後はビルドできない。`make_env_swift.sh` で空文字列のダミーを作る（広告は表示されない）。
- **空白チェックは変更差分だけ**：既存の Markdown には改行用の行末スペースがあるため、リポジトリ全体を検査すると必ず失敗する（初回のCIで実際に失敗した）。ローカルの規定（`git diff --check`）と同じく、PRでは `main` との分岐点から、push では直前のコミットからの差分だけを見る。
- **権限は `contents: read` だけ**：書き込み権限が不要なため最小にした。
- **実行の取り消しはPRだけ**：PRは新しいpushで古い実行を取り消して待ち時間を減らす。`main` は各コミットの結果を残すため取り消さない（レビューで修正）。

---

## 4. Xcode Cloud（`iOS/TransitICScanner/ci_scripts/`）

Xcode Cloud のワークフロー自体は App Store Connect / Xcode に保存され、リポジトリには置けない。リポジトリ側には、ワークフローの各段階で動くスクリプトと、連携用の `xcshareddata/xcodecloud/manifest.json`（IDだけのファイル）を置く。

| ファイル | 実行タイミング | 内容と意図 |
|---|---|---|
| `make_env_swift.sh` | 他スクリプトや GitHub Actions から呼ぶ | `env.swift` の生成本体。GitHub Actions と Xcode Cloud で同じ処理を使う |
| `ci_pre_xcodebuild.sh` | 各アクションの xcodebuild 直前 | `env.swift` を生成する。Archive では広告ユニットIDを必須にする |
| `ci_post_xcodebuild.sh` | 各アクションの xcodebuild 後 | 指定がある場合だけ TestFlight の「テスト内容」を生成する |

### `make_env_swift.sh` の安全策
- **値をログに出さない**：出力するのは「設定済みのIDで生成した／ダミーで生成した」だけ。
- **形式の検証**：値を Swift の文字列リテラルに埋め込むため、`ca-app-pub-<数字>/<数字>` 以外は拒否する。誤った値や `"` を含む値でソースが壊れたり、任意のコードが混入したりするのを防ぐ。
- **配布用では未設定をエラーにする**：`REQUIRE_AD_UNIT_IDS=1` のとき、IDが未設定ならビルドを止める。広告IDが空のまま App Store に出るのを防ぐため。このチェックは「既存の `env.swift` を残す」処理より先に行う（レビューで修正）。
- **ローカルの `env.swift` を上書きしない**：環境変数が未設定で `env.swift` がすでにある場合は、そのまま残す。開発者が手元でスクリプトを実行しても本番の設定が消えない。

### `ci_pre_xcodebuild.sh`（旧 `ci_post_clone.sh`）
最初はクローン直後（post-clone）で `env.swift` を生成していた。しかし、Archive かどうかの判定に使う `CI_XCODEBUILD_ACTION` は、ビルドの直前（pre-xcodebuild）の段階なら確実に参照できる。判定がもれると「Archive なのに未設定エラーにならない」状態になるため、生成をビルド直前に移した（レビューで修正）。

### `ci_post_xcodebuild.sh`
- TestFlight の「テスト内容」は**外部テスターにも表示される**。コミットの件名には Issue 番号や作業者など内部向けの情報が含まれるため、**既定では生成しない**。ワークフローの環境変数で `TESTFLIGHT_NOTES_FROM_COMMITS=1` を指定した場合だけ、直近10件の件名から `TestFlight/WhatToTest.ja.txt` / `WhatToTest.en-US.txt` を作る（レビューで修正）。
- 「テスト内容」は4000文字までなので3900バイトで切る。バイト単位で切ると日本語の文字が途中で切れるため、`iconv -c` で不完全な文字を取り除く。`iconv -c` はこの場合に終了コード1を返し、そのままだとArchiveが失敗するので、終了コードは無視する（レビューで修正）。
- 生成物（`iOS/TransitICScanner/TestFlight/`）は `.gitignore` に入れ、コミットしない。

---

## 5. 機密情報の扱い

- 広告ユニットIDは Xcode Cloud のシークレット環境変数だけに置き、リポジトリ・ログ・GitHub Actions には置かない。
- `manifest.json` は Xcode Cloud のプロダクトIDとターゲットIDだけで、認証情報は含まれない。
- `DEVELOPMENT_TEAM`（チームID）は以前からプロジェクトファイルにある値で、配布されるアプリにも含まれる識別子のため秘密情報ではない。
- GitHub Actions のアクションは `@v4` のタグで指定している。より厳密にする場合はコミットSHAで固定し、Dependabot で更新する。

---

## 6. 未対応・今後の候補

- テストのシミュレータを `iPhone 18 Pro` に固定している。ランナーのイメージ更新で機種がなくなったら `SIMULATOR_DESTINATION` を変更する。
- Release ビルドは GitHub Actions では行わず、Xcode Cloud の Archive で確認する。
- 実機・実カードでの読取確認は自動化できないため、従来どおり手動で行い、結果をIssue・PRに記録する。
