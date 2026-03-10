#!/bin/bash

# Build APK WITH ADS (for publishing)
echo "🚀 Building Simo WITH ADS..."
echo "This version will be used for publishing to app stores."
echo ""

flutter clean
flutter pub get
flutter build apk --dart-define=ENABLE_ADS=true --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "📦 APK location: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "Renaming to: simo-with-ads.apk"
    cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/simo-with-ads.apk
    echo "✅ Done!"
    echo ""
    ls -lh build/app/outputs/flutter-apk/simo-with-ads.apk
else
    echo "❌ Build failed!"
    exit 1
fi
