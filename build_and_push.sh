#!/bin/bash
set -e

WORKSPACE_DIR=$(pwd)
TOOLS_DIR="$WORKSPACE_DIR/.local_tools"

export JAVA_HOME="$TOOLS_DIR/jdk-17.0.2"
export PATH="$JAVA_HOME/bin:$TOOLS_DIR/flutter/bin:$PATH"
export ANDROID_HOME="$WORKSPACE_DIR/.local_tools/android_sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

flutter config --android-sdk "$ANDROID_HOME" 2>/dev/null

echo "Building APK..."
flutter build apk --release

echo "Copying APK..."
mkdir -p releases
cp build/app/outputs/flutter-apk/app-release.apk releases/mafia-nightfall.apk

echo "Committing and pushing..."
git add -A lib/ releases/mafia-nightfall.apk
git commit -m "Fix: Arabic text, settings save, role badges, re-vote logic, day screen roles"
git push origin master:main

echo "Done!"
