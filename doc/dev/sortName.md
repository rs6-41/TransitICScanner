# ソート名

## 概要
カード一覧画面でのソートの各言語対応

## 実装
翻訳ファイルに定義する。   
カード名：cardList.xxx.sortName
地域名：cardList.area.xx.sortName

     
### 日本語
地域名：
+ 一般的な読み方でひらがな表記にする
+ 濁点・半濁点を除去 → 小文字（捨て仮名）の大文字化を行う
+ あいうえお順を数字に対応させてスラッシュ区切りで記載（変換サイト：https://nazostep.jp/tools/letter-number）

```   
例）
akasi → あかし → 1/6/12
日本 → にほん → 22/30/46
```

カード名：
ローマ字化して英語表記として扱う
     
### 英語
一般的な地域名を小文字で記載（記号やスペースを除去）
```   
例）
Japan → japan
United States of America → america
```