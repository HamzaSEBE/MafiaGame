#!/bin/bash
set -e

echo "Starting setup..."

WORKSPACE_DIR=$(pwd)
TOOLS_DIR="$WORKSPACE_DIR/.local_tools"
mkdir -p "$TOOLS_DIR"

echo "Setting up JDK 17..."
if [ ! -d "$TOOLS_DIR/jdk-17.0.2" ]; then
  cd "$TOOLS_DIR"
  curl -O https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz
  tar -xf openjdk-17.0.2_linux-x64_bin.tar.gz
  rm openjdk-17.0.2_linux-x64_bin.tar.gz
  cd "$WORKSPACE_DIR"
fi
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

git add releases/mafia-nightfall.apk README.md lib/presentation/
git commit -m "Fix Arabic text, add APK and download button" || echo "Nothing to commit"

echo "Build and setup complete!"
