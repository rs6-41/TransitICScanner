# Worldwide Transit IC Balance Checker / 世界IC残高確認

An application that scans transit IC cards worldwide and retrieves their balances and transaction history.  
全世界の交通系ICカードをスキャンし、残高や利用履歴を確認できるアプリです。

- [Development Environment & Guidelines / 開発環境・規程](./doc/dev/README.md)

## Platforms / プラットフォーム

| OS | Link / リンク | Requirements / 要件 | External Reader / 外部リーダー |
| -- | -- | -- | -- |
| iOS | [App Store](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) | iOS 26.4+ | Supported / 対応 |
| macOS | [App Store](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) | macOS 26.4+ | Required / 必須 |
| Android | Not implemented / 未実装 | TBD / 未定 | TBD / 未定 |
| HarmonyOS | Not implemented / 未実装 | HarmonyOS NEXT | TBD / 未定 |
| Windows | Not implemented / 未実装 | Windows 11 | Required / 必須 |

## Supported Cards / 対応状況

**Note:** The built-in NFC reader on iPhone does not support reading MIFARE Classic cards.  
**注:** iPhone内蔵NFCリーダーではMIFARE Classicカードを読み取ることができません。

### East Asia / 東アジア

| Region / 地域 | Name / 名称 | Implementation ID / 実装名 | NFC | Standard / 規格 | Status / 実装状況 | Notes / 備考 |
| -- | -- | -- | -- | -- | -- | -- |
| Japan / 日本 | Japanese Transit IC / 交通系IC | jpIC | Type-F | [Cybernetics / サイバネ](./doc/cards/jpIC.md) | ✅ | |
| Mainland China / 中国本土 | China T-Union / 交通联合 | cnTunion | Type-A | [China T-Union / 交通联合](./doc/cards/cnTunion.md) | ✅ | |
| Hong Kong / 香港 | Octopus / 八達通 | hkOctopus | Type-F | [Octopus](./doc/cards/hkOctopus.md) | ✅ | A China T-Union-compatible version also exists / 交通联合版も存在 |
| Macau / マカオ | Macau Pass / マカオパス | | Type-A | MIFARE Classic | | A China T-Union-compatible version also exists / 交通联合版も存在 |
| Taiwan / 台湾 | EasyCard / 悠遊卡 | | Type-A | MIFARE Classic | Web scraping / スクレイピング | |
| Taiwan / 台湾 | Super EasyCard / 超級悠遊卡 | | Type-A | | | A next-generation version that supports reading and writing via smartphones / スマートフォンで読み書きできる新世代版 |
| Taiwan / 台湾 | iPASS / 一卡通 | | Type-A | MIFARE Classic | | |
| Taiwan / 台湾 | iPASS Plus / 一卡通 PLUS | | Type-A | | | A next-generation version that supports reading and writing via smartphones / スマートフォンで読み書きできる新世代版 |
| Taiwan / 台湾 | iCash / 愛金卡 | twIcash | Type-A | [iCash](./doc/cards/twIcash.md) | ✅ | |
| South Korea / 韓国 | OneCard AllPass | krOneCard | Type-A | [KS X 6924](./doc/cards/krOneCard.md) | ✅ | |
| North Korea (Pyongyang) / 北朝鮮（平壌） | Pyongyang Transit Card (Green) / 平壌交通カード（緑） | | Type-A | MIFARE Classic | | |
| North Korea (Pyongyang) / 北朝鮮（平壌） | Pyongyang Transit Card (Blue) / 平壌交通カード（青） | | Type-A | MIFARE Classic | | |

#### Japan (Regional Cards) / 日本（地方）

**Note:** 🈹Partial Cybernetics compatibility indicates that the card is not fully compatible with the Cybernetics standard, but shares its specifications except for the service codes.  
**注:** 🈹サイバネとは、サイバネ規格との互換性はないものの、サービスコードを除き、サイバネ規格と共通の仕様を採用していることを示します。

| Region / 地域 | Name / 名称 | Implementation ID / 実装名 | NFC | Standard / 規格 | Status / 実装状況 | Notes / 備考 |
| -- | -- | -- | -- | -- | -- | -- |
| Hokkaido / 北海道 | DoCard / Asaca | | Type-F | Proprietary / 独自 | | |
| Sapporo / 札幌 | SAPICA | jpIC_SAPICA | Type-F | [🈹Partial Cybernetics / 🈹サイバネ](./doc/cards/jpIC.md) | ✅ | |
| Kagawa / 香川 | IruCa | jpIC_IruCa | Type-F | [🈹Partial Cybernetics / 🈹サイバネ](./doc/cards/jpIC.md) | ✅ | |
| Nagasaki / 長崎 | Nagasaki N+ Card / エヌタス | jpNplus | Type-F | [Nagasaki N+ Card / エヌタス](./doc/cards/jpNplus.md) | ✅ | |
| Miyazaki / 宮崎 | icsca | jpIC_icsca | Type-F | [🈹Partial Cybernetics / 🈹サイバネ](./doc/cards/jpIC.md) | ✅ | |
| Kagoshima / 鹿児島 | Rapica / Iwasaki IC Card / いわさきICカード | jpRapica | Type-F | [Rapica](./doc/cards/jpRapica.md) | ✅ | |

### North America / 北アメリカ

| Region / 地域 | Name / 名称 | Implementation ID / 実装名 | NFC | Standard / 規格 | Status / 実装状況 | Notes / 備考 |
| -- | -- | -- | -- | -- | -- | -- |
| United States (San Francisco) / 米国（サンフランシスコ） | Clipper | usClipper | Type-A | [Clipper](./doc/cards/usClipper.md) | ✅ | |