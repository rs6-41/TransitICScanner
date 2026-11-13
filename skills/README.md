# カード開発スキル

このフォルダに、過去カードの事例から共通化した手順・テンプレート・検証ツールをまとめています。リポジトリのAGENTS.mdから、対象工程のSKILL.mdを読み込んで使用します。

| 入口 | 対象 |
|---|---|
| [交通ICカードの調査・文書化・iOS実装](transit-card-workflow/SKILL.md) | 調査/iOS実装Issue作成、調査済み情報の仕様書化、仕様書からのコード作成 |
| [1言語からの翻訳補完](transit-localization/SKILL.md) | 任意の入力言語から他の不足言語を補完し、必要な文脈をxcstringsのJSON `comment`へ記録 |

例：「`skills/transit-card-workflow/SKILL.md`を使って、指定カードの調査とiOS実装Issueを作成して」「`skills/transit-localization/SKILL.md`を使って、指定キーの日本語から他言語を補完して」のように、対象カード・キーと必要な工程を指定します。

`references/` は工程別の判断基準と過去事例、`assets/` はIssue・仕様書・カタログのテンプレート、`scripts/` は検証コードです。旧 `script/` は廃止し、命名チェックと回帰テストをカード開発スキル配下へ移しました。旧簡体字→繁体字変換は翻訳スキルへ置き換えました。

検証コマンドは [開発手順](../doc/dev/README.md)、スキルの保守規定は [AGENTS.md](AGENTS.md) を参照してください。翻訳チェック用Pythonのテストは次で実行できます。

```sh
python3 skills/transit-localization/scripts/test_check_xcstrings.py
```
