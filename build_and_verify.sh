#!/bin/bash

# Configuration
FLUTTER_PATH="/home/aginies/devel/flutter/bin/flutter"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
APKSIGNER_PATH="$HOME/Android/Sdk/build-tools/36.1.0/apksigner"
KEYSTORE_PATH="android/upload-keystore.jks"

function show_help() {
    echo "SecureMark Build & Verify Script"
    echo "Usage: ./build_and_verify.sh [command1] [command2] ..."
    echo ""
    echo "Available commands:"
    echo "  create_keystore   - Generate a new upload-keystore.jks (interactive)"
    echo "  cleanup           - Remove build artifacts (flutter clean)"
    echo "  update_deps       - Update flutter dependencies (pub get)"
    echo "  quality_checks    - Run analyze and tests"
    echo "  generate_assets   - Regenerate icons and splash screens"
    echo "  increment_version - Increment build number in pubspec.yaml"
    echo "  build_apk         - Build signed release APK"
    echo "  build_aab         - Build signed release App Bundle"
    echo "  verify_apk        - Verify APK signature with apksigner"
    echo "  verify_aab        - Verify AAB signature with jarsigner"
    echo "  collect_artifacts - Move and rename artifacts to releases/ folder"
    echo "  all               - Run full pipeline in sequence"
    echo "  help              - Show this help message"
}

function cleanup() {
    echo "[INFO] Cleaning up previous builds..."
    $FLUTTER_PATH clean
}

function update_deps() {
    echo "[INFO] Updating Flutter dependencies..."
    $FLUTTER_PATH pub get
}

function quality_checks() {
    echo "[INFO] Running static analysis..."
    $FLUTTER_PATH analyze || { echo "[ERROR] Analysis failed. Fix issues before building."; exit 1; }
    
    echo "[INFO] Running tests..."
    $FLUTTER_PATH test || { echo "[ERROR] Tests failed. Fix issues before building."; exit 1; }
    
    echo "[SUCCESS] Quality checks passed."
}

function generate_assets() {
    echo "[INFO] Regenerating launcher icons..."
    $FLUTTER_PATH pub run flutter_launcher_icons || echo "[WARNING] Icon generation failed, continuing..."
}

function increment_version() {
    echo "[INFO] Incrementing build number..."
    # Extracts version: 1.0.8+1 -> 1.0.8 and 1
    VERSION_LINE=$(grep "version: " pubspec.yaml)
    VERSION_NAME=$(echo $VERSION_LINE | cut -d' ' -f2 | cut -d'+' -f1)
    BUILD_NUMBER=$(echo $VERSION_LINE | cut -d'+' -f2)
    NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
    
    NEW_VERSION="version: $VERSION_NAME+$NEW_BUILD_NUMBER"
    sed -i "s/$VERSION_LINE/$NEW_VERSION/g" pubspec.yaml
    
    echo "[SUCCESS] Version updated to $VERSION_NAME+$NEW_BUILD_NUMBER"
}

function build_apk() {
    echo "[INFO] Building Release APK..."
    $FLUTTER_PATH build apk --release
}

function build_aab() {
    echo "[INFO] Building Release App Bundle (AAB)..."
    $FLUTTER_PATH build appbundle --release
}

function verify_apk() {
    if [ -f "$APK_PATH" ]; then
        echo "[INFO] Verifying APK signature..."
        $APKSIGNER_PATH verify --print-certs "$APK_PATH" | grep -E "Signer #|DN:"
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] APK signature verified successfully."
        else
            echo "[ERROR] APK signature verification failed!"
        fi
    else
        echo "[WARNING] APK file not found at $APK_PATH"
    fi
}

function verify_aab() {
    if [ -f "$AAB_PATH" ]; then
        echo "[INFO] Verifying AAB signature..."
        jarsigner -verify "$AAB_PATH" | head -n 1
        # Check if it's using the production key by looking for the alias
        jarsigner -verify -verbose -certs "$AAB_PATH" | grep "upload" > /dev/null
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] AAB production signature (upload alias) confirmed."
        else
            echo "[WARNING] AAB verified but 'upload' alias not found. Check if it's a debug signature."
        fi
    else
        echo "[WARNING] AAB file not found at $AAB_PATH"
    fi
}

function collect_artifacts() {
    VERSION_LINE=$(grep "version: " pubspec.yaml)
    VERSION_NAME=$(echo $VERSION_LINE | cut -d' ' -f2 | tr '+' '-')
    RELEASE_DIR="releases/v$VERSION_NAME"
    
    echo "[INFO] Collecting artifacts into $RELEASE_DIR..."
    mkdir -p "$RELEASE_DIR"
    
    if [ -f "$APK_PATH" ]; then
        cp "$APK_PATH" "$RELEASE_DIR/SecureMark-$VERSION_NAME.apk"
        echo "[SUCCESS] APK copied."
    fi
    
    if [ -f "$AAB_PATH" ]; then
        cp "$AAB_PATH" "$RELEASE_DIR/SecureMark-$VERSION_NAME.aab"
        echo "[SUCCESS] AAB copied."
    fi
}

function create_keystore() {
    if [ -f "$KEYSTORE_PATH" ]; then
        echo "[WARNING] Keystore already exists at $KEYSTORE_PATH"
        read -p "Do you want to overwrite it? (y/N): " confirm
        if [[ $confirm != [yY] ]]; then
            echo "Operation cancelled."
            return
        fi
    fi

    echo "[INFO] Generating new keystore..."
    keytool -genkey -v -keystore "$KEYSTORE_PATH" \
            -alias upload -keyalg RSA -keysize 2048 -validity 10000
    
    echo "[SUCCESS] Keystore created at $KEYSTORE_PATH"
}

function all() {
    cleanup
    update_deps
    quality_checks
    generate_assets
    increment_version
    build_apk
    build_aab
    echo ""
    echo "------------------------------------------------------------"
    echo "[INFO] Build Complete. Starting Verification..."
    echo "------------------------------------------------------------"
    verify_apk
    verify_aab
    collect_artifacts
    echo "------------------------------------------------------------"
    echo "[SUCCESS] Process Finished! Artifacts are in releases/ folder."
}

# Show help by default if no arguments are provided
if [ $# -eq 0 ]; then
    show_help
else
    # Allow calling specific functions passed as arguments
    for func in "$@"; do
        if [ "$func" == "help" ]; then
            show_help
        elif declare -f "$func" > /dev/null; then
            "$func"
        else
            echo "[ERROR] Function '$func' not found."
            echo "Run ./build_and_verify.sh without arguments to see available commands."
            exit 1
        fi
    done
fi
