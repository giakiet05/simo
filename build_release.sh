#!/bin/bash

# Build release APK (single file)
echo "Building release APK..."
flutter build apk --release

# Get version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)

# Rename APK
echo "Renaming APK with version $VERSION..."
cd build/app/outputs/flutter-apk

mv app-release.apk "simo-v${VERSION}.apk" 2>/dev/null

echo "Done! APK file:"
ls -lh simo-*.apk

echo ""
echo "File is in: build/app/outputs/flutter-apk/"
