#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION="1.6.0"
echo "=== Building SilverSpoon Linux Packages (v$VERSION) ==="

# 1. Ensure virtual environment has pyinstaller
if [ ! -f ".venv/bin/pyinstaller" ]; then
    echo "Installing PyInstaller in virtualenv..."
    .venv/bin/pip install pyinstaller
fi

# 2. Build standalone binary with PyInstaller
echo "--> 1. Compiling with PyInstaller..."
.venv/bin/pyinstaller --noconfirm --clean --noconsole --onedir \
  --icon="SilverSpoon.png" \
  --add-data "SilverSpoon.ico:." \
  --add-data "SilverSpoon.png:." \
  --add-data "theme_assets:theme_assets" \
  --copy-metadata "curl_cffi" \
  --exclude-module "cv2" \
  --exclude-module "numpy" \
  --exclude-module "matplotlib" \
  --exclude-module "scipy" \
  --exclude-module "pandas" \
  --exclude-module "torch" \
  --exclude-module "torchvision" \
  --exclude-module "IPython" \
  --exclude-module "PIL" \
  --exclude-module "Pillow" \
  --exclude-module "tkinter" \
  --exclude-module "unittest" \
  --exclude-module "pytest" \
  --exclude-module "PyQt6.QtPdf" \
  --name "silverspoon" \
  pyqt_downloader.py

mkdir -p dist

# 3. Build Portable Tarball
echo "--> 2. Creating portable .tar.gz archive..."
tar -czf "dist/silverspoon-${VERSION}-linux-x86_64.tar.gz" -C dist silverspoon

# 4. Build RPM Package (Fedora / RHEL / openSUSE)
if command -v rpmbuild >/dev/null 2>&1; then
    echo "--> 3. Building RPM package..."
    RPM_DIR="$SCRIPT_DIR/build/rpmbuild"
    rm -rf "$RPM_DIR"
    mkdir -p "$RPM_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    rpmbuild -bb \
      --define "_topdir $RPM_DIR" \
      --define "_sourcedir $SCRIPT_DIR" \
      packaging/silverspoon.spec
    cp "$RPM_DIR"/RPMS/*/*.rpm dist/
fi

# 5. Build DEB Package (Debian / Ubuntu / Linux Mint)
if command -v ar >/dev/null 2>&1; then
    echo "--> 4. Building DEB package..."
    DEB_TMP="$(mktemp -d)"
    echo "2.0" > "$DEB_TMP/debian-binary"
    
    mkdir -p "$DEB_TMP/control_dir"
    cat << EOF > "$DEB_TMP/control_dir/control"
Package: silverspoon
Version: ${VERSION}
Section: net
Priority: optional
Architecture: amd64
Maintainer: SilverSpoon Contributors <silverspoon@github.com>
Depends: google-chrome-stable | chromium | chromium-browser, p7zip-full | p7zip
Description: Fast bulk downloader with Cloudflare Turnstile solver
 Bulk downloader designed to bypass Cloudflare Turnstile protections
 on file-hosting sites like fuckingfast.co and datanodes.to.
EOF
    tar -czf "$DEB_TMP/control.tar.gz" -C "$DEB_TMP/control_dir" control
    
    mkdir -p "$DEB_TMP/data_dir/opt/silverspoon"
    mkdir -p "$DEB_TMP/data_dir/usr/bin"
    mkdir -p "$DEB_TMP/data_dir/usr/share/applications"
    mkdir -p "$DEB_TMP/data_dir/usr/share/icons/hicolor/256x256/apps"
    
    cp -r dist/silverspoon/* "$DEB_TMP/data_dir/opt/silverspoon/"
    ln -sf /opt/silverspoon/silverspoon "$DEB_TMP/data_dir/usr/bin/silverspoon"
    cp packaging/silverspoon.desktop "$DEB_TMP/data_dir/usr/share/applications/"
    cp SilverSpoon.png "$DEB_TMP/data_dir/usr/share/icons/hicolor/256x256/apps/silverspoon.png"
    tar -czf "$DEB_TMP/data.tar.gz" -C "$DEB_TMP/data_dir" .
    
    (cd "$DEB_TMP" && ar rcs "$SCRIPT_DIR/dist/silverspoon_${VERSION}_amd64.deb" debian-binary control.tar.gz data.tar.gz)
    rm -rf "$DEB_TMP"
fi

# 6. Build AppImage (Universal Linux)
echo "--> 5. Building AppImage (universal for any Linux distro)..."
APPDIR="$(mktemp -d)/SilverSpoon.AppDir"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/icons/hicolor/256x256/apps" "$APPDIR/usr/share/applications"
cp -r dist/silverspoon/* "$APPDIR/usr/bin/"
cp packaging/silverspoon.desktop "$APPDIR/"
cp packaging/silverspoon.desktop "$APPDIR/usr/share/applications/"
cp SilverSpoon.png "$APPDIR/silverspoon.png"
cp SilverSpoon.png "$APPDIR/.DirIcon"
cp SilverSpoon.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/silverspoon.png"

cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/silverspoon" "$@"
EOF
chmod +x "$APPDIR/AppRun"

TOOL_TMP="$(mktemp -d)"
curl -sL https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -o "$TOOL_TMP/appimagetool"
chmod +x "$TOOL_TMP/appimagetool"
(cd "$TOOL_TMP" && ./appimagetool --appimage-extract >/dev/null 2>&1)
ARCH=x86_64 "$TOOL_TMP/squashfs-root/AppRun" "$APPDIR" "dist/SilverSpoon-${VERSION}-x86_64.AppImage"
rm -rf "$APPDIR" "$TOOL_TMP"

echo ""
echo "=================================================="
echo "Successfully built Linux distribution packages in dist/:"
ls -lh dist/*.{rpm,deb,tar.gz,AppImage} 2>/dev/null
echo "=================================================="
