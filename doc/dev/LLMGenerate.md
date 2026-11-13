# カード開発と翻訳のスキル

入口はリポジトリ最上位の [`skills/`](../../skills/README.md)。規定はAGENTS.md、工程の進め方はSKILL.md、カード固有の根拠は `doc/cards/` で管理する。

- [カード開発スキル](../../skills/transit-card-workflow/SKILL.md)：調査/iOS実装Issue作成、調査済み情報の仕様書化、仕様書からのiOS実装。Issue・仕様書のテンプレートと過去カードの参照例を同梱。
- [翻訳スキル](../../skills/transit-localization/SKILL.md)：ユーザーが入力した1言語を基準に他言語を補完する。文脈はSwiftのコメントアウトではなく、xcstringsの各キー直下のJSON `comment`へ記録する。

調査から実装まで一括で依頼する場合も、根拠・未確認事項・実施した検証を工程間で引き継ぐ。ダンプの取得や実機アクセスは別途その利用時の依頼範囲で行い、既存コードの解釈を公式仕様や実測結果として扱わない。

検証補助コードは `skills/transit-card-workflow/scripts/` と `skills/transit-localization/scripts/` に配置する。旧 `script/` は廃止済み。
