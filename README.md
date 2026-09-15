# 世界IC残高確認
全世界の交通系ICをスキャンできるアプリ

## 対応状況
iOSではMifare Classicの読み取りができない。

### 東アジア
| 地域 | 名称 | 実装名 | NFC | 規格 | iOS | Android | 備考 |
| -- | -- | -- | -- | -- | -- | -- | -- |
| 日本 | 交通系IC | jpIC | Type-F | [サイバネ](https://github.com/rs6-41/TransitICScanner/wiki/サイバネ規格) | ✅ | | |
| 中国本土 | China T-Union | cnTunion | Type-A | [交通联合](https://github.com/rs6-41/TransitICScanner/wiki/交通联合) | | | |
| 香港 | Octopus | hkOctopus | Type-F | | ✅ | | 交通联合版も存在 |
| マカオ | マカオパス | | Type-A | Mifare Classic | ✅ | | 交通联合版も存在 |
| 台湾 | EasyCard | | Type-A | Mifare Classic | ✅ | | |
| 台湾 | Super EasyCard | | Type-A | | ✅ | | スマホで読み書きできる新世代版 |
| 台湾 | iPass | | Type-A | Mifare Classic | ✅ | | |
| 台湾 | iPass Plus | | Type-A | | ✅ | | スマホで読み書きできる新世代版 |
| 台湾 | iCash | twIcash | Type-A | | ✅ | | |
| 韓国 | OneCard AllPass | krOneCard | NFC Type-A | KS X 6924 | ✅ | | |
| 北朝鮮 | 平壌交通カード（緑） | | NFC Type-A | Mifare Classic | ✖️ | | |
| 北朝鮮 | 平壌交通カード（青） | | NFC Type-A | Mifare Classic | ✖️ | | |

#### 日本（地域限定）
🈹サイバネ = サイバネ規格との互換性はないが、サービスコード以外はサイバネ規格と共通仕様であることを指す
| 地域 | 名称 | 実装名 | NFC | 規格 | iOS | Android | 備考 |
| -- | -- | -- | -- | -- | -- | -- | -- |
| 北海道 | DoCard/Asaca | | Type-F | 独自 | | | |
| 札幌 | SAPICA | jpIC_other | Type-F | 🈹サイバネ | ✅ | | |
| 香川 | IruCa | jpIC_other | Type-F | 🈹サイバネ | ✅ | | |
| 長崎 | N+ | jpNplus | Type-F | 独自 | ✅ | | |

## コミットメッセージ規定
絵文字 + Issues番号 + 内容
|絵文字|意味|
| -- | -- |
|📃|ドキュメントの更新|
|✨|新機能の追加|
|🐛|バグの修正|
|♻️|コードの整理|
|💄|UI・デザインの変更|
|⚡️|パフォーマンス改善|
|✅|テストの追加・修正|
