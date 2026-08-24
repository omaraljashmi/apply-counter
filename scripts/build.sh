#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
build_dir="${project_dir}/build"
app_bundle="${build_dir}/Apply Counter.app"
contents_dir="${app_bundle}/Contents"
module_cache="${build_dir}/module-cache"
host_arch="$(uname -m)"
default_sdk="$(xcrun --sdk macosx --show-sdk-path)"
local_compat_sdk="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"

if [[ -n "${APPLY_COUNTER_SDK_PATH:-}" ]]; then
    sdk_path="${APPLY_COUNTER_SDK_PATH}"
elif [[ -d "${local_compat_sdk}" ]]; then
    sdk_path="${local_compat_sdk}"
else
    sdk_path="${default_sdk}"
fi

mkdir -p "${contents_dir}/MacOS" "${contents_dir}/Resources" "${module_cache}"

CLANG_MODULE_CACHE_PATH="${module_cache}" \
SWIFT_MODULE_CACHE_PATH="${module_cache}" \
swiftc \
    -O \
    -parse-as-library \
    -sdk "${sdk_path}" \
    -target "${host_arch}-apple-macosx14.0" \
    -framework AppKit \
    -framework SwiftUI \
    -framework Combine \
    "${project_dir}/App/ApplyCounter.swift" \
    -o "${contents_dir}/MacOS/Apply Counter"

cp "${project_dir}/Info.plist" "${contents_dir}/Info.plist"
cp "${project_dir}/assets/cat-trio-cream.png" "${contents_dir}/Resources/cat-trio-cream.png"

codesign --force --deep --sign - "${app_bundle}"

echo "Built ${app_bundle}"
