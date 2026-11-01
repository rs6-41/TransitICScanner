# 世界IC残高確認
全世界の交通系ICをスキャンできるアプリ

 - [開発環境・規程](./doc/dev/README.md)
 
## プラットフォーム
| OS | 実装状況 | 要件 | 外部リーダー |
| -- | -- | -- | -- |
| iOS | [AppStore](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) | iOS 26.4+ | 対応 |
| macOS | [AppStore](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) | macOS 26.4+ | 必須 |
| Android | 未実装 | Windows 11 | 未定 |
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
| 台湾 | EasyCard | | Type-A | Mifare Classic | [スクレイピング](./doc/cards/twEasyCard_old.md) | |
| 台湾 | Super EasyCard | | Type-A | | | スマホで読み書きできる新世代版 |
| 台湾 | iPass | | Type-A | Mifare Classic |  | |
| 台湾 | iPass Plus | | Type-A | |  | | スマホで読み書きできる新世代版 |
| 台湾 | iCash | twIcash | Type-A | [iCash](./doc/cards/twIcash.md) | ✅ | |
| 韓国 | OneCard AllPass | krOneCard | NFC Type-A | [KS X 6924](./doc/cards/krOneCard.md) | ✅ | |
| 北朝鮮 | 平壌交通カード（緑） | | NFC Type-A | Mifare Classic | | |
| 北朝鮮 | 平壌交通カード（青） | | NFC Type-A | Mifare Classic | | |

#### 日本（地方）
🈹サイバネ = サイバネ規格との互換性はないが、サービスコード以外はサイバネ規格と共通仕様であることを指す
| 地域 | 名称 | 実装名 | NFC | 規格 | 実装状況 | 備考 |
| -- | -- | -- | -- | -- | -- | -- |
| 北海道 | DoCard/Asaca | | Type-F | 独自 | | | |
| 札幌 | SAPICA | jpIC_SAPICA | Type-F | [🈹サイバネ](./doc/cards/jpIC.md) | ✅ | |
| 香川 | IruCa | jpIC_IruCa | Type-F | [🈹サイバネ](./doc/cards/jpIC.md) | ✅ | |
| 長崎 | エヌタス | jpNplus | Type-F | [エヌタス](./doc/cards/jpNplus.md) | ✅ | |
| 宮崎 | icsca | jpIC_icsca | Type-F | [🈹サイバネ](./doc/cards/jpIC.md) | ✅ | |
| 鹿児島 | Rapica/いわさきICカード | jpRapica | Type-F | [Rapica](./doc/cards/jpRapica.md) | ✅ | |

### 北アメリカ
| 地域 | 名称 | 実装名 | NFC | 規格 | 実装状況 | 備考 |
| -- | -- | -- | -- | -- | -- | -- |
| 米国(サンフランシスコ) | Clipper | usClipper | Type-A | [Clipper](./doc/cards/usClipper.md) | ✅ | |