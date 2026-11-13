# 仕様書からiOSコードを作る

## 開始条件

`doc/cards/<cardID>.md` 全文、ルート・Apple実装・CardDefine配下のAGENTS.md、`doc/dev/ARCHITECTURE.md`、`doc/dev/sortName.md` を読む。仕様書の未確認事項から実装可能な範囲を決める。重大な入力仕様を推測して動くコードで埋めない。

[過去事例](card-cases.md)から読取方式に合う例を選び、型・非同期処理・分岐の構造を読む。既存カードのコードが仕様と違っていたりエラー処理が不十分でも、同じ挙動を新規カードへコピーしない。

## 実装と登録

| 対象 | 変更・確認する点 |
|---|---|
| `Scan/CardModel.swift` | CardID、CardInfo、ScanOption、必要な既存モデルとの整合 |
| `CardDefine/<cardID>/` | 読取・解析、UpperCamelCaseのConverter、純粋な解析処理の分離 |
| `CardDefine/ScannerBranch.swift` | 内蔵・外部の分岐、FeliCa共有分岐、公開状態に合う一覧への登録 |
| `CardDefine/ConverterType.swift` | caseとcardInfo/historyの分岐 |
| `Info.plist` | 必要なFeliCa System Code／ISO7816 AIDの登録 |
| `Localize/Localizable.xcstrings` | 名前・短縮名・ソート名・一覧説明・結果説明・券種・発行情報のキーと翻訳 |
| `Assets.xcassets` / `CardDesigns.swift` | 実在するロゴ・券面、参照名、既定デザイン |
| `Area.swift` / `PrefectureSort.swift` | 必要な地域・通貨・並び順。既存定義があれば再利用 |
| `project.pbxproj` | 同期グループとWatch/Widgetの共有ファイル登録・例外 |
| `README.md` / `README_en.md` / 仕様書 / ARCHITECTURE | 実装・公開状態、リンク、構成の反映 |

FeliCaは `FeliCaTagReading` に対する1つの読取実装を共有する。ISO7816/DESFireは `APDUSend` に解析を寄せ、セッション終了・接続管理だけをリーダー側へ置く。MIFARE Classicやスクレイピングは内蔵NFC対応と偽らず、対象方式の既存経路へ統合する。

履歴識別子は再読取で同じ取引を同じものとして扱える仕様根拠を確認する。未知の種別・読取失敗・不正長を正常なゼロ残高へ変えない。実装した根拠があるデータだけを表示する。

## 保存と公開

既存カードのID・キー・画像を変更する場合は、保存モデルとCloudKit・Widget・Watchへの影響を確認する。必要な旧値の解決は `Utility/CardIdentity.swift` に集約し、型や保存プロパティを改名する場合はマイグレーションを別途設計する。

サンプルは根拠のある公開サンプルを使う。完全なサンプルがなければ不足を明記し、登録設計上必須である場合も架空の実測データで穴埋めしない。実カード確認の根拠がなければ自動でrelCardsへ登録しない。

## 検証

スキル同梱のPythonはリポジトリルートから実行する。

```sh
python3 skills/transit-card-workflow/scripts/check_naming.py
python3 skills/transit-card-workflow/scripts/test_idkai.py
python3 skills/transit-card-workflow/scripts/test_idkai_identity.py
python3 skills/transit-card-workflow/scripts/test_widget_compatibility.py
git diff --check
```

命名チェックとSwift lintは共通確認。KAIの2テストはKAI読取・ID互換処理に影響する場合、WidgetテストはWidget保存契約に影響する場合に実行する。新カードには対象の本番パーサーを使うテストを追加する。既存のKAIテストだけで新カードを検証済みとしない。

SwiftDataのテストはmacOS/Xcodeのマクロ実行が必要で、実行環境により追加権限が必要になる。テストは合成データと一時ストアを使い、利用者の本番ストアには接続しない。

短い・空・不正なデータ、未知種別、件数境界、金額の符号・単位、日時境界、終端と通信障害、再読取時の重複排除を対象にする。ビルド対象はApple実装AGENTS.mdに従う。シミュレータのcompile-only、UI操作、実機カード確認は別々に記録する。

完了報告は仕様項目との照合結果、変更・登録箇所、実施した検証、未確認事項を含める。Git・Issue・PRへの投稿はユーザーの依頼範囲とリポジトリの規定に従う。
