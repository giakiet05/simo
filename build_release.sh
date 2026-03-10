#!/bin/bash

# Build release APK with ads enabled
echo "🚀 Building Simo release APK WITH ADS..."
echo ""

# Clean build
echo "🧹 Cleaning previous build..."
flutter clean
flutter pub get

# Get version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)
echo "📦 Building version $VERSION..."
echo ""

# Build APK with ads enabled
flutter build apk --dart-define=ENABLE_ADS=true --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""

    # Rename APK with version
    cd build/app/outputs/flutter-apk
    mv app-release.apk "simo-v${VERSION}.apk" 2>/dev/null

    echo "📱 APK file:"
    ls -lh simo-*.apk
    echo ""
    echo "📂 Location: build/app/outputs/flutter-apk/"
    echo ""
    echo "ℹ️  This build includes ads (Banner + Rewarded)"
    echo "ℹ️  Ad-free duration after watching rewarded ad: 12 hours"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
