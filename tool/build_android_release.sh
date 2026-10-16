#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_root"
# This is an explicit local testing mode, preserving the existing APK identity.
# Ordinary release builds continue to require android/key.properties.
if [[ ${1:-} == --existing-test-signature ]]; then
  export ORG_GRADLE_PROJECT_useExistingTestSigning=true
elif [[ $# -gt 0 ]]; then
  echo 'Usage: tool/build_android_release.sh [--existing-test-signature]' >&2
  exit 2
fi
if [[ -z ${JAVA_HOME:-} && -x "$project_root/.local_tools/jdk-17.0.2/bin/javac" ]]; then
  export JAVA_HOME="$project_root/.local_tools/jdk-17.0.2"
  export PATH="$JAVA_HOME/bin:$PATH"
fi
flutter_command=flutter
if [[ -x "$project_root/.local_tools/flutter/bin/flutter" ]]; then
  flutter_command="$project_root/.local_tools/flutter/bin/flutter"
fi
# One Gradle worker, no persistent daemon, and no simulator or browser.
"$flutter_command" build apk --release --no-pub --target-platform android-arm64 --split-per-abi
