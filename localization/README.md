# 翻訳CSVの編集と反映

このディレクトリのCSVは各プラットフォームで共通利用できます。同期スクリプトの反映先は以下のiOS文字列カタログです。

| CSV | 反映先（アプリのソースディレクトリからの相対パス） |
| --- | --- |
| `Localizable.csv` | `Localize/Localizable.xcstrings` |
| `InfoPlist.csv` | `Localize/InfoPlist.xcstrings` |
| `cnTunion_cards.csv` | `CardDefine/cnTunion/cnTunion_cards.xcstrings` |

## CSVを編集する

- 1行に1キーを記入します。先頭列は `key,comment,en,ja,zh-Hans,zh-Hant` の順です。追加ロケールはその後に列を追加します。UTF-8で保存してください。BOM付きのUTF-8も読み込めます。
- 既存行では対象言語のセルを編集します。追加する場合は行を増やし、既存行と重複しないキーと少なくとも1言語の文言、またはコメントを記入します。
- `comment` はキー単位の文脈や用途を記録する列です。出力時にカタログのコメントが入り、CSVで入力・編集したコメントはカタログに反映されます。
- 空欄のセルとCSVにない行はカタログの既存データを維持します。削除や空文字への変更はXcode側で行い、CSVを再出力してください。
- `%@`、`%lld` などの書式指定子を維持してください。Excel等で編集する場合は、キーや文言が日付・数値・数式に変換されないよう、各列をテキストとして読み込んでください。

## カタログへ反映する

リポジトリのルートで実行します。Python 3.8以上と標準ライブラリで動作します。

```sh
python3 localization/sync_localizations.py --dry-run
python3 localization/sync_localizations.py
git diff -- '*.xcstrings'
```

`--dry-run` は検証と変更対象キー数の表示のみを行います。通常実行はすべてのCSVを検証してからカタログを更新します。追加キーは `manual` として登録し、追加・変更した文言は `translated` に設定します。値が同じ文言の翻訳状態や、編集対象外のメタデータは維持します。複数形などの構造化翻訳はXcodeで編集してください。

## カタログからCSVを再出力する

Xcodeやソースからカタログが更新された場合は、CSVの未反映変更を確認してから再出力します。`--export` はすべてのCSVを上書きします。

```sh
python3 localization/sync_localizations.py --export
```
