# EZ-Link（シンガポール）

カードIDとConverterは `spEZLink`。従来型CEPASのPurse 3を読み取る。CAN先頭の `100` でEZ-Linkを識別する。PC/SCとCoreNFCのISO 14443経路で読み取り処理を共有する。SimplyGoのサーバー管理残高は対象外。

## 読み取り

| 順番 | APDU | 内容 |
| -- | -- | -- |
| 1 | `90 32 03 00 00` | Purse 3を読み取る。SW1が `6C` でSW2が非ゼロの場合は指定のLeで一度再送。残高読み取りが `6700` の場合は、実測の応答長80バイトをLeに指定して一度再送する |
| 2 | `00 A4 00 00 02 40 00 00` | Purse 3の読み取りがステータスエラーの場合はファイルID `4000` を選択し、読み取りをやり直す |

各コマンドはSW1が `90` の場合に成功として扱う。応答本文のオフセットは0始まり。残高はオフセット2の符号付き24ビット、ビッグエンディアンで、単位はSGDセント。オフセット8から8バイトのCANをカード識別子とし、10進数字で構成されるEZ-Linkの `100` プレフィックスを要求する。本文は取引レコードまでの固定領域62バイト以上とする。実測のPurse応答は80バイトで、発行者データの長さフィールドから推定したサイズより短かった。残高とCANは固定領域から読み、後続の発行者データは解析対象に含めない。これらの条件を満たさない応答は読み取り失敗として扱う。

外部リーダーで残高取得に必要なコマンドが `6F00` を返すか、残高取得の長さ調整後も `6700` が返る場合、または成功ステータスでも固定領域が62バイト未満の場合は、セッションを閉じて250ミリ秒待ち、新しいセッションで最初から再試行する。初回を含め最大3回。

## 履歴

同じ Read Purse APDUにデータ1バイトを付ける。初回は `00`、2回目は初回応答のレコード件数を指定する。各ページは最大256バイト、1レコード16バイト。Purse応答のオフセット40にある履歴件数を1ページ目で満たした場合は2ページ目を要求しない。最大2ページを取得し、最初のページで `6A83` が返れば履歴なしとして扱う。必要な履歴ページの取得に失敗した場合は残高のみ表示する。

| オフセット | 長さ | 内容 |
| -- | -- | -- |
| 0 | 1 | 取引種別 |
| 1 | 3 | 符号付きSGDセント、ビッグエンディアン |
| 4 | 4 | 1995-01-01 00:00:00 SGTからの秒数、ビッグエンディアン |
| 8 | 8 | 取引付加情報。画面では表示せず、取引識別子の生成に使う |

全ゼロのレコードを除外する。スキャン時のPurse残高を最新取引の取引後残高とし、取引日時の降順で符号付き取引額を差し引いて、各取引後の残高をSGDセント単位で逆算する。同時刻のレコードはカードの応答順を維持する。応答順は任意項目として保存し、復元後の同時刻の並べ替えにも使う。以前の保存データでは再スキャンで一致する取引に応答順を補う。履歴には取引後残高と取引額を表示する。取引識別子には16バイトのレコード全体のSHA-256先頭64ビットを使う。

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
- 同じEZ-Link実カードで、統合後に残高と履歴の表示を確認した。診断時の履歴1ページ目は `9000` で176バイト、2ページ目は `6A80`。当時の実装では1ページ目だけを表示していた。

- 2026-11-25、読み取れなくなったEZ-LinkでPurse読み取り時の `6700` と、別の試行でファイル選択時の `6F00` を確認した。Leの再送処理追加後、同じカードで残高と履歴の表示を確認した。

- 再検証では正常な80バイトのPurse応答と、同じカードで成功ステータス付きの48バイトおよび2バイトの応答を確認した。短い応答を受けた場合に再接続しても、全試行で復旧することは確認できていない。

### 読み取りトレース

DebugビルドのXcodeコンソールで `EZ-Link trace` を絞り込む。経路、スキャンごとのランダムID、試行番号、外部リーダーの交渉済みプロトコル、APDUヘッダー、Lc・Le、履歴オフセット、SW、応答長、所要時間、送信エラーのドメインとコードを確認できる。カード番号、残高、履歴の内容、応答バイト列は出力しない。

2026-11-25に、2015年ごろの実カードを同じ外部リーダーで3回スキャンした。すべてのセッションはT=1で開始した。1回目は残高APDUが `9000`・80バイト、履歴の初回APDUは `6F00` だった。残り2回ではファイル選択が `9000`・11バイトで成功した後、残高APDUがLe=256とLe=80の両方で `6700`・0バイトを返した。セッションを開き直しても再現した。カード本体、無線通信、リーダー内部のどこで応答が変わるかは未特定。

カードを外さず連続スキャンした別の試行では、1回目にPurse 80バイトと履歴11件を取得した。2回目の最初のPurse応答は `9000`・48バイトだった。この応答でもファイルを再選択する実験を行ったところ、選択は成功したが、その後のPurse応答がLe=256・80ともに `6700` となり、セッションを開き直しても復旧しなかった。
