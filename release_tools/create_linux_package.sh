#!/bin/bash

cd ..

echo "Extracting the version number from pubspec.yaml"
VERSION=$(grep ^version pubspec.yaml | cut -d ' ' -f 2)

if [ -z "$VERSION" ]; then
  echo "Error: Could not extract version number from pubspec.yaml"
  exit 1
fi

VERSION=$(echo "$VERSION" | tr -d '\r')

BUNDLE_DIR="build/linux/x64/release/bundle"
OUTPUT_DIR="release_tools/LinuxPackage"
TAR_FILE="kpix-$VERSION-x86_x64.tar.gz"

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: Bundle directory not found at $BUNDLE_DIR"
  exit 1
fi

echo "Create the output directory if it doesn't exist"
mkdir -p "$OUTPUT_DIR"

echo "Create a tar.gz file of the build bundle contents"
tar -czf "$TAR_FILE" -C "$BUNDLE_DIR" .
mv -f "$TAR_FILE" "$OUTPUT_DIR/"

