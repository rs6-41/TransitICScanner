#!/bin/sh
# Xcode Cloud: xcodebuild の後に実行される。
# Archiveが成功したら、直近のコミットからTestFlightの「テスト内容」を生成する。
# Xcode Cloudは ci_scripts と同じ階層の TestFlight/WhatToTest.<locale>.txt を読み込む。
set -eu

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ] || [ -z "${CI_ARCHIVE_PATH:-}" ]; then
    exit 0
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
notes_dir="$script_dir/../TestFlight"
mkdir -p "$notes_dir"

# TestFlightの「テスト内容」は4000文字まで。
git -C "$CI_PRIMARY_REPOSITORY_PATH" log -10 --pretty=format:'- %s' | head -c 3900 > "$notes_dir/WhatToTest.ja.txt"
cp "$notes_dir/WhatToTest.ja.txt" "$notes_dir/WhatToTest.en-US.txt"
echo "TestFlight notes generated from recent commits."
