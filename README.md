[English](README_en.md)

# 世界IC残高確認

[![Swift 6.4.2](https://img.shields.io/badge/Swift-6.4.2-orange?logo=swift&logoColor=white)](./doc/dev/README.md)
[![Xcode 27.2](https://img.shields.io/badge/Xcode-27.2-147EFB?logo=xcode&logoColor=white)](./doc/dev/README.md)
[![iOS 26.4+](https://img.shields.io/badge/iOS-26.4%2B-blue?logo=apple&logoColor=white)](#プラットフォーム)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4%2B-blue?logo=apple&logoColor=white)](#プラットフォーム)
[![App Store](https://img.shields.io/badge/App_Store-Download-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/app/id6812794719)
[![CI](https://img.shields.io/github/actions/workflow/status/rs6-41/TransitICScanner/ci.yml?branch=main&label=CI&logo=github)](https://github.com/rs6-41/TransitICScanner/actions/workflows/ci.yml)

全世界の交通系ICをスキャンできるアプリ

## プラットフォーム
| OS | リンク | 要件 | 外部リーダー |
| -- | -- | -- | -- |
| iOS | [AppStore](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) / [Testflight](https://testflight.apple.com/join/GYrHt3mb) | iOS 26.4+ | 対応 |
| macOS | [AppStore](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) / [Testflight](https://testflight.apple.com/join/GYrHt3mb)  | macOS 26.4+ | 必須 |
| watchOS | [Testflight](https://testflight.apple.com/join/GYrHt3mb)  | watchOS 26.4+ | - |
| Android | 未実装 | 未定 | 未定 |
| HarmonyOS | 未実装 | HarmonyOS NEXT | 未定 |
| Windows | 未実装 | 未定 | 必須 |

 - [開発環境・規程](./doc/dev/README.md)
 - [LLMによる開発スキル](./skills/README.md)
 - [LLM作業用のIssueテンプレート](./.github/ISSUE_TEMPLATE/00-00_agent.yml)

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

### 東南アジア

- シンガポール [EZ-Link / NETS FlashPay（CEPAS）](./doc/cards/spFlashPay.md) — 開発用一覧に残高・取引履歴の読み取りを実装。EZ-Linkの残高と履歴はMacのPaSoRiで確認済み。

### 北アメリカ
| 地域 | 名称 | 実装名 | NFC | 規格 | 実装状況 | 備考 |
| -- | -- | -- | -- | -- | -- | -- |
| 米国(サンフランシスコ) | Clipper | usClipper | Type-A | [Clipper](./doc/cards/usClipper.md) | ✅ | |
