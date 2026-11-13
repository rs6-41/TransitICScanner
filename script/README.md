# 自動化スクリプト

## 翻訳
### 简体字→繁体字
iOS：`./iOS/xcstrings_chinese_simple_to_traditional.swift `
中国語の简体字翻訳を繁体字に変換します。  
※ 普通語を前提に繁体字翻訳を作成するため、繁体字圏での表現（主に台湾華語）になっているか要確認。  
※ 広東語は大幅に異なるため自動化スクリプトは使用しない。

## 検証

[共通規定](../AGENTS.md)と[スクリプト規定](AGENTS.md)に従い、リポジトリルートで実行します。Python 3が必要で、Swift回帰テストにはmacOSとXcodeのコマンドラインツールも必要です。

```sh
python3 script/check_naming.py
python3 script/tests/test_idKMT.py
python3 script/tests/test_widget_compatibility.py
```

- `check_naming.py`：追跡中・新規の非ignore Swiftファイルの型・関数・変数宣言を検証します。ASCII識別子の大文字・小文字とアンダースコアを対象とし、意味に応じた命名や保存キーの互換性はレビューで確認します。
- `tests/test_idKMT.py`：本番のKMT解析・読取処理を抽出し、合成バイト列で不正データ・スライス・件数境界を検証します。
- `tests/test_widget_compatibility.py`：本番のWidgetモデルを抽出し、旧JSONのdecode、旧キーを維持したencode、編集・省略可能項目を検証します。
