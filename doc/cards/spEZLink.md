# EZ-Link（シンガポール）

カードIDとConverterは `spEZLink`。従来型CEPASのPurse 3を読み取る。CAN先頭の `100` でEZ-Linkを識別する。PC/SCとCoreNFCのISO 14443経路で読み取り処理を共有する。SimplyGoのサーバー管理残高は対象外。

## 読み取り

| 順番 | APDU | 内容 |
| -- | -- | -- |
| 1 | `90 32 03 00 00` | Purse 3を読み取る。SW1が `6C` でSW2が非ゼロの場合は指定のLeで一度再送 |
| 2 | `00 A4 00 00 02 40 00 00` | Purse 3の読み取りがステータスエラーの場合はファイルID `4000` を選択し、読み取りをやり直す |

各コマンドはSW1が `90` の場合に成功として扱う。応答本文のオフセットは0始まり。残高はオフセット2の符号付き24ビット、ビッグエンディアンで、単位はSGDセント。オフセット8から8バイトのCANをカード識別子とし、10進数字で構成されるEZ-Linkの `100` プレフィックスを要求する。本文は取引レコードまでの固定領域62バイト以上とする。実測のPurse応答は80バイトで、発行者データの長さフィールドから推定したサイズより短かった。残高とCANは固定領域から読み、後続の発行者データは解析対象に含めない。これらの条件を満たさない応答は読み取り失敗として扱う。

## 履歴

同じ Read Purse APDUにデータ1バイトを付ける。初回は `00`、2回目は初回応答のレコード件数を指定する。各ページは最大256バイト、1レコード16バイト。最大2ページを取得し、最初のページで `6A83` が返れば履歴なしとして扱う。2ページ目が取得できない場合は取得済みの1ページ目を表示する。1ページ目の読取エラー時も残高は表示する。

| オフセット | 長さ | 内容 |
| -- | -- | -- |
| 0 | 1 | 取引種別 |
| 1 | 3 | 符号付きSGDセント、ビッグエンディアン |
| 4 | 4 | 1995-01-01 00:00:00 SGTからの秒数、ビッグエンディアン |
| 8 | 8 | 取引付加情報。画面では表示せず、取引識別子の生成に使う |

全ゼロのレコードを除外する。スキャン時のPurse残高を最新取引の取引後残高とし、取引日時の降順で符号付き取引額を差し引いて、各取引後の残高をSGDセント単位で逆算する。同時刻のレコードはカードの応答順を維持する。履歴には取引後残高と取引額を表示する。取引識別子には16バイトのレコード全体のSHA-256先頭64ビットを使う。

## iOS実装

調査は #76、iOS実装は #175。開発用一覧の「EZ-Link」からスキャンする。

| ファイル | 責務 |
| -- | -- |
| `CardDefine/spEZLink/spEZLink.swift` | カード定義、CoreNFC・外部リーダーの接続、共通APDU読取 |
| `CardDefine/spEZLink/SPEZLinkPurse.swift` | 残高とCANの解析、発行元の判定 |
| `CardDefine/spEZLink/SPEZLinkHistory.swift` | 取引レコードの解析、取引IDの生成、取引後残高の逆算 |
| `CardDefine/spEZLink/SPEZLinkConverter.swift` | 表示名、通貨、取引種別の変換 |

同じ取引IDが保存済みの場合、再スキャンで取得できた取引の残高を更新する。保存済み履歴のうち再スキャンで取得できなかった取引には、保存時の値を維持する。

## 根拠と確認状況

- 規格資料（2026-11-25確認） [SS 518:2014 Amendment No. 1](https://www.singaporestandardseshop.sg/Product/DownloadPdf/8f49243e-aa55-445e-a752-49f79c8fbe50?Page=3)
- 公開実装（2026-11-25確認） [MetrodroidのCEPASファイル選択](https://github.com/metrodroid/metrodroid/blob/master/src/commonMain/kotlin/au/id/micolous/metrodroid/card/cepas/CEPASApplication.kt)、[Purse読取](https://github.com/metrodroid/metrodroid/blob/master/src/commonMain/kotlin/au/id/micolous/metrodroid/card/cepas/CEPASProtocol.kt)、[残高の形式](https://github.com/metrodroid/metrodroid/blob/master/src/commonMain/kotlin/au/id/micolous/metrodroid/transit/ezlink/CEPASPurse.kt)、[Purse番号・発行者識別](https://github.com/metrodroid/metrodroid/blob/master/src/commonMain/kotlin/au/id/micolous/metrodroid/transit/ezlink/EZLinkTransitData.kt)
- 公開実装（2026-11-25確認） [FareBotのPurse直接読み取り](https://github.com/codebutler/farebot/blob/main/card/cepas/src/commonMain/kotlin/com/codebutler/farebot/card/cepas/CEPASCardReader.kt)
- Mac Catalyst版のDevスキームで、接続済みPaSoRiと実カードを用いてSGD残高が表示されることを確認した。一部の試行ではPurse読み取りとファイル選択がともに `6F00` で失敗し、再スキャンでは `9000` のPurse応答を受信した。

- 履歴形式の根拠は [MetrodroidのCEPASTransaction](https://github.com/metrodroid/metrodroid/blob/master/src/commonMain/kotlin/au/id/micolous/metrodroid/transit/ezlink/CEPASTransaction.kt)。
- iPhone内蔵NFCでの実カード動作は未確認。
- CoreNFCの検出設定に、[FareBotのiOS設定](https://github.com/codebutler/farebot/blob/main/app/ios/FareBot/Info.plist)と同じNFC Forum Type 4 NDEFアプリケーション識別子 `D2760000850101` を追加した。CEPASのファイルID `4000` はAPDUで選択する。
- 同じEZ-Link実カードで、統合後に残高と履歴の表示を確認した。診断時の履歴1ページ目は `9000` で176バイト、2ページ目は `6A80`。2ページ目が取得できなくても1ページ目の取得済みレコードを保持する。
