#!/bin/bash

cd ..

echo "Extracting the version number from pubspec.yaml"
VERSION=$(grep ^version pubspec.yaml | cut -d ' ' -f 2)

if [ -z "$VERSION" ]; then
  echo "Error: Could not extract version number from pubspec.yaml"
  exit 1
fi
VERSION=$(echo "$VERSION" | tr -d '\r')

APPIMAGE_TOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous"
APPIMAGE_EXEC="appimagetool-x86_64.AppImage"
BUNDLE_DIR="build/linux/x64/release/bundle"
OUTPUT_DIR="release_tools/LinuxAppImage"
APPDIR_PATH="KPix.AppDir"
ICON_PATH="imgs/kpix_icon.png"
APPRUN_FILE="$OUTPUT_DIR/$APPDIR_PATH/AppRun"
DESKTOP_FILE="$OUTPUT_DIR/$APPDIR_PATH/KPix.desktop"
OUTPUT_FILE_NAME="KPix-$VERSION-x86_64.AppImage"

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: Bundle directory not found at $BUNDLE_DIR"
  exit 1
fi

echo "Create the output directory if it doesn't exist"
mkdir -p "$OUTPUT_DIR"

echo "Downloading appimagetool"
wget "$APPIMAGE_TOOL_URL/$APPIMAGE_EXEC"

if [ ! -f "$APPIMAGE_EXEC" ]; then
  echo "Error: Download of appimagetool was not successful!"
  exit 1
fi

chmod +x "$APPIMAGE_EXEC"

echo "Copying build directory"
cp -r "$BUNDLE_DIR" "$OUTPUT_DIR/$APPDIR_PATH"

echo "Copying icon"
cp "$ICON_PATH" "$OUTPUT_DIR/$APPDIR_PATH/kpix.png"

echo "Creating AppRun file"
touch "$APPRUN_FILE"
if [ ! -f "$APPRUN_FILE" ]; then
  echo "Error: Could not create AppRun file!"
  exit 1
fi

cat > "$APPRUN_FILE" << 'EOF'
#!/bin/sh

cd "$(dirname "$0")"
exec ./kpix
EOF

chmod +x "$APPRUN_FILE"


echo "Creating .desktop file"
touch "$DESKTOP_FILE"
if [ ! -f "$DESKTOP_FILE" ]; then
  echo "Error: Could not create .desktop file!"
  exit 1
fi

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=$VERSION
Type=Application
Terminal=false
Name=KPix
Comment=KPix is a pixel art editor for still images and animations with a focus on generative color ramps and shading.
Exec=kpix %u
Icon=kpix
Categories=Graphics;
Keywords=pixelart;
PrefersNonDefaultGPU=true
SingleMainWindow=true
EOF


echo "Creating AppImage package"
"./appimagetool-x86_64.AppImage" "$OUTPUT_DIR/$APPDIR_PATH" "$OUTPUT_DIR/$OUTPUT_FILE_NAME"

echo "Removing temporary files"
rm -r "$OUTPUT_DIR/$APPDIR_PATH"
rm -f "$APPIMAGE_EXEC" "$APPIMAGE_EXEC".[0-9]*
