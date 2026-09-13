#!/bin/bash

# Build APK WITHOUT ADS (for personal use)
echo "🚀 Building Simo WITHOUT ADS..."
echo "This version will be used for personal use (no ads)."
echo ""

flutter clean
flutter pub get
flutter build apk --dart-define=ENABLE_ADS=false --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "📦 APK location: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "Renaming to: simo-no-ads.apk"
    cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/simo-no-ads.apk
    echo "✅ Done!"
    echo ""
    ls -lh build/app/outputs/flutter-apk/simo-no-ads.apk
else
    echo "❌ Build failed!"
    exit 1
fi
