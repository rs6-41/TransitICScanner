#!/bin/sh
# Xcode Cloud: xcodebuild の後に実行される。
# TESTFLIGHT_NOTES_FROM_COMMITS=1 のワークフローでArchiveが成功したら、
# 直近のコミット件名からTestFlightの「テスト内容」を生成する。
# 外部テスターにも表示されるため、内部向けのコミット文を公開しないよう既定では生成しない。
# Xcode Cloudは ci_scripts と同じ階層の TestFlight/WhatToTest.<locale>.txt を読み込む。
set -eu

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ] || [ -z "${CI_ARCHIVE_PATH:-}" ]; then
    exit 0
fi

if [ "${TESTFLIGHT_NOTES_FROM_COMMITS:-0}" != "1" ]; then
    exit 0
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
notes_dir="$script_dir/../TestFlight"
mkdir -p "$notes_dir"

# TestFlightの「テスト内容」は4000文字まで。バイト単位で切った末尾の不完全なUTF-8はiconvで除く。
# iconv -c は不完全な文字を除いた上で終了コード1を返すため、ビルド失敗にしないよう無視する。
git -C "$CI_PRIMARY_REPOSITORY_PATH" log -10 --pretty=format:'- %s' > "$notes_dir/commits.txt"
head -c 3900 "$notes_dir/commits.txt" | iconv -c -f UTF-8 -t UTF-8 > "$notes_dir/WhatToTest.ja.txt" 2>/dev/null || true
rm -f "$notes_dir/commits.txt"
cp "$notes_dir/WhatToTest.ja.txt" "$notes_dir/WhatToTest.en-US.txt"
echo "TestFlight notes generated from recent commits."
