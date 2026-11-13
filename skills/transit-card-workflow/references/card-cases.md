# 過去カードの使い分け

以下はスキル作成時にリポジトリとGitHubを確認した例。パスは対象リポジトリ基準。カード固有の値を別カードの根拠にしない。

| 観点 | 主な参照先 | 共通化する点・注意点 |
|---|---|---|
| 調査とiOS Issueの分離 | [KAI調査 #118](https://github.com/rs6-41/TransitICScanner/issues/118)、[KAI実装 #77](https://github.com/rs6-41/TransitICScanner/issues/77)、[DoCard実装 #71](https://github.com/rs6-41/TransitICScanner/issues/71) | 調査は根拠と解釈、実装は登録と検証を完了条件にする。チェック済みだけで今回の実機確認を宣言しない |
| Issue本文の流用 | [Clipper #69](https://github.com/rs6-41/TransitICScanner/issues/69) | iOSのタイトルに調査用チェックがある例。今回の工程に必要な項目へ作り直す |
| FeliCa・バイト解析・終端 | `doc/cards/idKAI.md`、`CardDefine/idKAI/idKAI.swift`、`Scan/FeliCa/FeliCaTagReading.swift` | リーダー共通化、非ゼロ開始添字のDataスライス、件数制限、不正応答長。履歴終端と通信障害の区別には未確認事項が残るため、万能な読取ヘルパーとして無条件に流用しない |
| 旧IDとの互換性 | `Utility/CardIdentity.swift`、`test_idkai_identity.py` | idKMTからidKAIへの統一。旧ID・ローカライズキー・画像の解決と、利用者の表示名・保存履歴の維持 |
| 独自FeliCa・年欠落 | `doc/cards/jpDoCard.md`、`CardDefine/jpDoCard/` | 共通のFeliCaインターフェースを使い、日付・年の解釈は対象カードの仕様に限定する |
| ISO7816 / FCI / TLV | `doc/cards/cnTunion.md`、`CardDefine/cnTunion/cnTunion+APDU.swift`、`cnTunion+FCI.swift`、`cnTunion+Records.swift` | コマンド送受信・管理情報・履歴解析を責務で分割する。ファイルID・タグの意味は新カードから確認する |
| DESFire・継続応答 | `doc/cards/usClipper.md`、`CardDefine/usClipper/usClipper.swift` | ファイル種別に応じた読取、追加フレーム、符号付き残高、Epoch・タイムゾーン。継続上限や日付規則を別カードへそのまま移さない |
| スクレイピング | `doc/cards/twEasyCard_old.md`、`CardDefine/twEasyCard_old/` | カード世代・NFC制限・Web経路・更新遅延・CAPTCHAを区別。世代名が似ていても別方式を同一実装としない |

`CardDefine/`・`Scan/`・`Utility/` は `iOS/TransitICScanner/TransitICScanner/` 以下。テストはこのスキルの `scripts/` 以下。

KAIの仕様書は「現行コードの解釈」と「未確認事項」を明示しており、解釈を公式仕様へ昇格させない書き方の例になる。カードの金額が取引後残高なのか取引額なのかを、モデルのフィールド名だけから決めない。
