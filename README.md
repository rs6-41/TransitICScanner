# 世界IC残高確認
全世界の交通系ICをスキャンできるアプリ

 - [開発環境・規程](./doc/dev/README.md)

## 対応状況
iOSではMifare Classicの読み取りができない。

### 東アジア
| 地域 | 名称 | 実装名 | NFC | 規格 | iOS | Android | 備考 |
| -- | -- | -- | -- | -- | -- | -- | -- |
| 日本 | 交通系IC | jpIC | Type-F | [サイバネ](./doc/cards/jpIC.md) | ✅ | | |
| 中国本土 | China T-Union | cnTunion | Type-A | [交通联合](./doc/cards/cnTunion.md) | ✅ | | |
| 香港 | Octopus | hkOctopus | Type-F | [Octopus](./doc/cards/hkOctopus.md) | ✅ | | 交通联合版も存在 |
| マカオ | マカオパス | | Type-A | Mifare Classic | | | 交通联合版も存在 |
| 台湾 | EasyCard | | Type-A | Mifare Classic | [スクレイピング](./doc/cards/twEasyCard_old.md) | | |
| 台湾 | Super EasyCard | | Type-A | |  | | スマホで読み書きできる新世代版 |
| 台湾 | iPass | | Type-A | Mifare Classic |  | | |
| 台湾 | iPass Plus | | Type-A | |  | | スマホで読み書きできる新世代版 |
| 台湾 | iCash | twIcash | Type-A | [iCash](./doc/cards/twIcash.md) | ✅ | | |
| 韓国 | OneCard AllPass | krOneCard | NFC Type-A | [KS X 6924](./doc/cards/krOneCard.md) | ✅ | | |
| 北朝鮮 | 平壌交通カード（緑） | | NFC Type-A | Mifare Classic | ✖️ | | |
| 北朝鮮 | 平壌交通カード（青） | | NFC Type-A | Mifare Classic | ✖️ | | |

#### 日本（地域限定）
🈹サイバネ = サイバネ規格との互換性はないが、サービスコード以外はサイバネ規格と共通仕様であることを指す
| 地域 | 名称 | 実装名 | NFC | 規格 | iOS | Android | 備考 |
| -- | -- | -- | -- | -- | -- | -- | -- |
| 北海道 | DoCard/Asaca | | Type-F | 独自 | | | |
| 札幌 | SAPICA | jpIC_other | Type-F | [🈹サイバネ](./doc/cards/jpIC.md) | ✅ | | |
| 香川 | IruCa | jpIC_other | Type-F | [🈹サイバネ](./doc/cards/jpIC.md) | ✅ | | |
| 長崎 | エヌタス | jpNplus | Type-F | [エヌタス](./doc/cards/jpNplus.md) | ✅ | | |