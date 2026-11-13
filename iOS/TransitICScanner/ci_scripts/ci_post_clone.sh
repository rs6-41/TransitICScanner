#!/bin/sh
# Xcode Cloud: クローン直後に実行される。非追跡の env.swift を生成する。
set -eu

script_dir=$(cd "$(dirname "$0")" && pwd)

# Archive（TestFlight・App Store配布）では広告ユニットIDの設定を必須にする。
if [ "${CI_XCODEBUILD_ACTION:-}" = "archive" ]; then
    export REQUIRE_AD_UNIT_IDS=1
fi

"$script_dir/make_env_swift.sh"
