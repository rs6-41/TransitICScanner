[English](README_en.md)

# 世界IC残高確認
全世界の交通系ICをスキャンできるアプリ

 - [開発環境・規程](./doc/dev/README.md)
 
## LLMによる開発スキル

生成AI（LLM）がこのリポジトリで利用する手順・テンプレート・検証ツールを、最上位の[skills/](./skills/README.md)にまとめています。

| スキル | 対象 |
| -- | -- |
| [カード開発・Issue作成](./skills/transit-card-workflow/SKILL.md) | 調査/iOS実装Issue、調査情報の仕様書化、仕様書からのiOS実装、文書・スキル整備のIssue |
| [翻訳補完](./skills/transit-localization/SKILL.md) | 任意の1言語から不足翻訳を補完。文脈説明はxcstringsのJSON内`comment`へ記録 |

利用するLLMに[ルートのAGENTS.md](./AGENTS.md)と対象の`SKILL.md`を読み込ませ、対象と必要な工程を指定してください。例えば「`skills/transit-card-workflow/SKILL.md`を使い、提供資料から指定カードの仕様書を作成して」「`skills/transit-localization/SKILL.md`を使い、指定キーの日本語から他言語を補完して」と依頼します。

スキルはこのプロジェクトの規定・モデル・構成に合わせた生成AI向けの指示書です。Issue投稿、コード変更、コミット、PR作成まで行う場合は、その範囲と対象ブランチも指定してください。LLMが作成・更新するIssue・PRには、既存ラベルを維持して`Agent`ラベルを必ず付与します。

## プラットフォーム
| OS | リンク | 要件 | 外部リーダー |
| -- | -- | -- | -- |
| iOS | [AppStore](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) | iOS 26.4+ | 対応 |
| macOS | [AppStore](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) | macOS 26.4+ | 必須 |
| watchOS | 未リリース | watchOS 26.4+ | - |
| Android | 未実装 | 未定 | 未定 |
| HarmonyOS | 未実装 | HarmonyOS NEXT | 未定 |
| Windows | 未実装 | 未定 | 必須 |

## 対応状況
注：iPhone内蔵リーダーではMifare Classicの読み取りができない。

### 東アジア
| 地域 | 名称 | 実装名 | NFC | 規格 | 実装状況 | 備考 |
| -- | -- | -- | -- | -- | -- | -- |
| 日本 | 交通系IC | jpIC | Type-F | [サイバネ](./doc/cards/jpIC.md) | ✅ | |
| 中国本土 | China T-Union | cnTunion | Type-A | [交通联合](./doc/cards/cnTunion.md) | ✅ | |
| 香港 | Octopus | hkOctopus | Type-F | [Octopus](./doc/cards/hkOctopus.md) | ✅ | 交通联合版も存在 |
| マカオ | マカオパス | | Type-A | Mifare Classic | | 交通联合版も存在 |
| 台湾 | EasyCard | twEasyCard_old | Type-A | Mifare Classic | [スクレイピング](./doc/cards/twEasyCard_old.md) | |
| 台湾 | Super EasyCard | | Type-A | | | スマホで読み書きできる新世代版 |
| 台湾 | iPass | | Type-A | Mifare Classic |  | |
| 台湾 | iPass Plus | | Type-A | | | スマホで読み書きできる新世代版 |
| 台湾 | iCash | twICash | Type-A | [iCash](./doc/cards/twICash.md) | ✅ | |
| 韓国 | OneCard AllPass | krOneCard | NFC Type-A | [KS X 6924](./doc/cards/krOneCard.md) | ✅ | |
| 北朝鮮 | 平壌交通カード（緑） | | NFC Type-A | Mifare Classic | | |
| 北朝鮮 | 平壌交通カード（青） | | NFC Type-A | Mifare Classic | | |

#### 日本（地方）
🈹サイバネ = サイバネ規格との互換性はないが、サービスコード以外はサイバネ規格と共通仕様であることを指す
| 地域 | 名称 | 実装名 | NFC | 規格 | 実装状況 | 備考 |
| -- | -- | -- | -- | -- | -- | -- |
| 北海道(旭川) | DoCard/Asaca | jpDoCard | Type-F | [DoCard/Asaca](./doc/cards/jpDoCard.md) | ✅ | |
| 札幌 | SAPICA | jpIC_SAPICA | Type-F | [🈹サイバネ](./doc/cards/jpIC.md) | ✅ | |
| 香川 | IruCa | jpIC_IruCa | Type-F | [🈹サイバネ](./doc/cards/jpIC.md) | ✅ | |
| 長崎 | エヌタス | jpNplus | Type-F | [エヌタス](./doc/cards/jpNplus.md) | ✅ | |
| 宮城 | icsca | jpIC_icsca | Type-F | [🈹サイバネ](./doc/cards/jpIC.md) | ✅ | |
| 沖縄 | OKICA | jpOKICA | Type-F | [OKICA](./doc/cards/jpOKICA.md) | ✅ | |
| 鹿児島 | Rapica/いわさきICカード | jpRapica | Type-F | [Rapica](./doc/cards/jpRapica.md) | ✅ | |

### 北アメリカ
| 地域 | 名称 | 実装名 | NFC | 規格 | 実装状況 | 備考 |
| -- | -- | -- | -- | -- | -- | -- |
| 米国(サンフランシスコ) | Clipper | usClipper | Type-A | [Clipper](./doc/cards/usClipper.md) | ✅ | |
