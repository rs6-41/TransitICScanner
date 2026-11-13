#!/bin/sh
# 非追跡の Ads/env.swift をCI用に生成する（GitHub Actions・Xcode Cloud共通）。
#
# - ADMOB_NATIVE_UNIT_ID / ADMOB_BANNER_UNIT_ID が設定されていればその値を使う。
#   Xcode Cloudではワークフローの「シークレット」環境変数として登録する。
# - 未設定なら空文字列のダミーを書く（テスト・ビルド確認用。広告は表示されない）。
# - REQUIRE_AD_UNIT_IDS=1 のときは未設定をエラーにする（配布用Archiveで使う）。
# 値の内容はログへ出力しない。
set -eu

script_dir=$(cd "$(dirname "$0")" && pwd)
env_file="$script_dir/../TransitICScanner/Ads/env.swift"

native_unit_id=${ADMOB_NATIVE_UNIT_ID:-}
banner_unit_id=${ADMOB_BANNER_UNIT_ID:-}

# 配布用では既存ファイルの有無にかかわらず、未設定を先にエラーにする。
if [ "${REQUIRE_AD_UNIT_IDS:-0}" = "1" ] && { [ -z "$native_unit_id" ] || [ -z "$banner_unit_id" ]; }; then
    echo "error: ADMOB_NATIVE_UNIT_ID and ADMOB_BANNER_UNIT_ID are required for distribution builds." >&2
    exit 1
fi

if [ -f "$env_file" ] && [ -z "$native_unit_id" ] && [ -z "$banner_unit_id" ]; then
    echo "env.swift already exists; keeping it."
    exit 0
fi

# Swift文字列リテラルへ埋め込むため、AdMobのユニットID形式以外は拒否する。
for value in "$native_unit_id" "$banner_unit_id"; do
    if [ -n "$value" ] && ! printf '%s' "$value" | grep -Eq '^ca-app-pub-[0-9]+/[0-9]+$'; then
        echo "error: AdMob unit ID has an unexpected format." >&2
        exit 1
    fi
done

cat > "$env_file" <<SWIFT
// CIで自動生成（ci_scripts/make_env_swift.sh）。コミットしない。
let NativeUnitID = "$native_unit_id"
let bannerUnitID = "$banner_unit_id"
SWIFT

if [ -n "$native_unit_id" ]; then
    echo "env.swift generated with configured ad unit IDs."
else
    echo "env.swift generated with empty placeholder ad unit IDs."
fi
