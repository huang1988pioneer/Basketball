#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-1.1.0}"
DIST="$ROOT/dist/v$VERSION"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

if [[ ! -x "$GODOT" ]]; then
  echo "Godot binary not found at $GODOT" >&2
  exit 1
fi

mkdir -p "$DIST" "$ROOT/build/ios"

echo "==> Importing project"
"$GODOT" --headless --path "$ROOT" --import --quit

export_one() {
  local preset="$1"
  local output="$2"
  echo "==> Exporting $preset -> $output"
  mkdir -p "$(dirname "$output")"
  if ! "$GODOT" --headless --path "$ROOT" --export-release "$preset" "$output"; then
    echo "WARNING: export failed for $preset" >&2
    return 1
  fi
}

export_one "Windows Desktop" "$DIST/Basketball-v$VERSION-windows-x86_64.exe" || true
export_one "macOS" "$DIST/Basketball-v$VERSION-macos-universal.zip" || true
export_one "Android" "$DIST/Basketball-v$VERSION-android.apk" || true
export_one "Android Unsigned" "$DIST/Basketball-v$VERSION-android-unsigned.apk" || true

IOS_ZIP="$DIST/Basketball-v$VERSION-ios-xcode-project.zip"
echo "==> Exporting iOS"
"$GODOT" --headless --path "$ROOT" --export-release "iOS" "$ROOT/build/ios/Basketball.zip" || {
  echo "iOS export failed; continuing with other artifacts" >&2
}

if [[ -f "$ROOT/build/ios/Basketball.zip" ]]; then
  cp "$ROOT/build/ios/Basketball.zip" "$IOS_ZIP"
elif [[ -d "$ROOT/build/ios" ]]; then
  (
    cd "$ROOT/build/ios"
    zip -r "$IOS_ZIP" . -x "*.DS_Store"
  )
fi

(
  cd "$DIST"
  shasum -a 256 Basketball-v$VERSION-windows-x86_64.exe \
    Basketball-v$VERSION-macos-universal.zip \
    Basketball-v$VERSION-android.apk \
    Basketball-v$VERSION-android-unsigned.apk \
    Basketball-v$VERSION-ios-xcode-project.zip \
    > SHA256SUMS.txt 2>/dev/null || true
)

echo "==> Artifacts in $DIST"
ls -lh "$DIST"
