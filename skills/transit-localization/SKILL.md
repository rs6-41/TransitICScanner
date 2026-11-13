---
name: transit-localization
description: TransitICScannerのxcstringsについて、ユーザーが指定した任意の1言語を基準に他の不足言語を翻訳・補完し、文脈をJSON内のcommentへ記録する。SwiftUIの表示にはLocalizedStringKeyを使う。カード仕様の調査や無関係な文言の一括変更には使わない。
---

# 1言語からローカライズを補完する

対象リポジトリのルートとAGENTS.mdを確認する。現在の主なカタログは `iOS/TransitICScanner/TransitICScanner/Localize/Localizable.xcstrings` と `InfoPlist.xcstrings`。キー・文言・入力言語が指定されていればその範囲を扱い、一般的なUI文言は前後の画面・呼び出し元から意味を確認する。

## 基準言語と対象言語

1. ユーザーが入力した言語と文言を基準として保存する。言語が判別できる場合は再質問しない。曖昧な短語や固有名詞で意味が変わる場合だけ確認し、判断できる他のキーは進める。
2. 対象言語はカタログ・プロジェクトの登録とユーザー指定から決める。現行は `en` / `ja` / `zh-Hans` / `zh-Hant`。入力が別言語なら指定された入力言語のエントリーを保持し、既存対象言語も補完する。新言語の全アプリ対応を自動で宣言しない。
3. 入力言語が日本語等でも、カタログ全体の `sourceLanguage` を変更しない。キーは意味のある既存の名前空間に合わせ、ユーザー指定のIDや保存互換性を優先する。
4. 指定キーの不足翻訳を補完する。既存の正しい訳は維持し、基準文言の意味が変更されて古い訳が不整合になった場合はそのキーの訳を更新する。原文の意味・数字・固有名詞を無断で増減しない。

## JSON内の文脈コメント

必要な説明は各キーのオブジェクトの `"comment"` に入れる。[JSON例](assets/xcstrings-entry.json) と [文脈・形式の詳細](references/catalog-contract.md) を参照する。

```json
"result.history.fare": {
  "comment": "取引履歴の種別ラベル。支払った運賃を表し、残高ではない。",
  "localizations": {}
}
```

これは配置箇所の例であり、既存のlocalizationsを空にしてはならない。`comment` は `stringUnit` や言語オブジェクトの内側ではなく、キー直下に置く。説明のために `//` や `/* */` のJSON外コメント、独自の `context` フィールドを追加しない。

短い語、単位、プレースホルダー、同音異義、正式名称と略称の区別など、翻訳判断に影響する文脈だけを記録する。既存コメントが誤っていたら用途を確認して修正し、有用な文脈は残す。未確認のカードの取引分類をコメントで断定しない。

## 翻訳とSwiftUI

- 構造は `strings[key].localizations[locale].stringUnit.{state,value}` を維持する。完成した訳だけを `translated` とする。
- 簡体字から繁体字への機械的な字形変換だけで完了にしない。地域に合う語彙・交通名称・通貨表現を選ぶ。正式なカード名は根拠なく音訳・別名化しない。
- `%@`、`%lld`、位置指定の `%1$@`、`%%`、改行、タグ、単位を確認する。文法に応じた引数の並び替えは位置指定で表現し、型・参照する引数は維持する。
- 既存の複数形・デバイスvariation・substitutions・extractionStateを平坦化しない。必要な構造をそのまま翻訳する。
- SwiftUIの表示は `Text(LocalizedStringKey("key"))` 等を使う。動的キーも `LocalizedStringKey(key)` とし、翻訳済み文字列を新しいキーとして再解釈しない。変数・保存等の表示以外の用途は既存 `localizedString(_:)` の責務に従う。
- コメントのためだけにSwiftのコメントアウトやAPIのcomment引数を追加せず、要求どおりJSONの `comment` を使う。

## 検証・報告

JSONが解析でき、指定キーに基準言語と対象言語があり、入力文言が保持されていることを確認する。通常のstringUnitは次で形式・プレースホルダーも検証できる。

```sh
python3 skills/transit-localization/scripts/check_xcstrings.py --catalog iOS/TransitICScanner/TransitICScanner/Localize/Localizable.xcstrings --source-language ja --keys 対象キー
```

複雑なvariationはこのチェックの対象外として通知される。上書きや削除でチェックを通さず、構造と各leafの引数を確認し、必要なXcodeビルドを行う。コード参照・表示幅・改行も変更範囲に応じて確認する。

変更したキー、基準言語、補完言語、追加した文脈コメント、実施した確認と未確認点を報告する。呼び出し元も変更した場合は、その用途に必要な検証を加える。
