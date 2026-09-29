#!/bin/bash
set -e

WORKSPACE_DIR=$(pwd)
TOOLS_DIR="$WORKSPACE_DIR/.local_tools"

export JAVA_HOME="$TOOLS_DIR/jdk-17.0.2"
export PATH="$JAVA_HOME/bin:$PATH"

export PATH="$TOOLS_DIR/flutter/bin:$PATH"
export ANDROID_HOME="$WORKSPACE_DIR/.local_tools/android_sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

flutter config --android-sdk "$ANDROID_HOME"

echo "Building APK..."
flutter build apk --release

echo "Setting up APK release..."
mkdir -p releases
cp build/app/outputs/flutter-apk/app-release.apk releases/mafia-nightfall.apk

echo "Initializing Git repository..."
if [ ! -d ".git" ]; then
  git init
  git remote add origin https://github.com/HamzaSEBE/MafiaGame.git
fi

git add releases/mafia-nightfall.apk README.md lib/
git commit -m "Fix Arabic text, add APK and download button" || echo "Nothing to commit"

echo "Build and setup complete!"
