#!/bin/bash

# Skaletek KYC iOS Setup Script
# This script automates the iOS setup process for AWS Amplify Face Liveness

echo "🔧 Skaletek KYC iOS Setup"
echo "========================="

# Find the Flutter project root
FLUTTER_ROOT=""
CURRENT_DIR="$(pwd)"

while [[ "$CURRENT_DIR" != "/" ]]; do
    if [[ -f "$CURRENT_DIR/pubspec.yaml" ]]; then
        FLUTTER_ROOT="$CURRENT_DIR"
        break
    fi
    CURRENT_DIR="$(dirname "$CURRENT_DIR")"
done

if [[ -z "$FLUTTER_ROOT" ]]; then
    echo "❌ Error: Could not find Flutter project root (no pubspec.yaml found)"
    echo "   Please run this script from within your Flutter project directory"
    exit 1
fi

echo "📱 Found Flutter project at: $FLUTTER_ROOT"

# Check if iOS directory exists
if [[ ! -d "$FLUTTER_ROOT/ios" ]]; then
    echo "❌ Error: iOS directory not found"
    echo "   Please ensure your Flutter project supports iOS"
    exit 1
fi

# Find the Skaletek KYC plugin setup script
SETUP_SCRIPT=""

# Try pub cache locations
PUB_CACHE_PATTERN="$HOME/.pub-cache/hosted/pub.dev/skaletek_kyc-*/ios/setup_amplify_ios.rb"
for script in $PUB_CACHE_PATTERN; do
    if [[ -f "$script" ]]; then
        SETUP_SCRIPT="$script"
        break
    fi
done

# Try local development path (if running from plugin directory)
if [[ -z "$SETUP_SCRIPT" && -f "ios/setup_amplify_ios.rb" ]]; then
    SETUP_SCRIPT="ios/setup_amplify_ios.rb"
fi

# Try relative path from Flutter project
if [[ -z "$SETUP_SCRIPT" && -f "$FLUTTER_ROOT/../ios/setup_amplify_ios.rb" ]]; then
    SETUP_SCRIPT="$FLUTTER_ROOT/../ios/setup_amplify_ios.rb"
fi

if [[ -z "$SETUP_SCRIPT" ]]; then
    echo "❌ Error: Skaletek KYC setup script not found"
    echo "   Please ensure the skaletek_kyc plugin is properly installed"
    echo "   Try running: flutter pub get"
    exit 1
fi

echo "🔍 Found setup script at: $SETUP_SCRIPT"

# Run the Ruby setup script
echo "🚀 Running iOS setup automation..."
ruby "$SETUP_SCRIPT" "$FLUTTER_ROOT"

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo ""
    echo "🎉 iOS setup completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Open Xcode: cd ios && open Runner.xcworkspace"
    echo "2. Add Swift Package Dependencies (see ios/AMPLIFY_SETUP_INSTRUCTIONS.md)"
    echo "3. Build and run your app"
else
    echo ""
    echo "❌ Setup failed with exit code $EXIT_CODE"
    echo "   Please check the error messages above and try again"
fi

exit $EXIT_CODE 