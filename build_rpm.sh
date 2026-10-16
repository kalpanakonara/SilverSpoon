#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Building SilverSpoon Linux Executable & RPM Package ==="

# 1. Ensure virtual environment has pyinstaller
if [ ! -f ".venv/bin/pyinstaller" ]; then
    echo "Installing PyInstaller in virtualenv..."
    .venv/bin/pip install pyinstaller
fi

# 2. Build with PyInstaller
echo "Compiling SilverSpoon standalone bundle with PyInstaller..."
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

# 3. Setup RPM build environment
RPM_DIR="$SCRIPT_DIR/build/rpmbuild"
rm -rf "$RPM_DIR"
mkdir -p "$RPM_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# 4. Build RPM
echo "Building RPM package..."
rpmbuild -bb \
  --define "_topdir $RPM_DIR" \
  --define "_sourcedir $SCRIPT_DIR" \
  packaging/silverspoon.spec

# 5. Copy built RPM to dist
mkdir -p dist
cp "$RPM_DIR"/RPMS/*/*.rpm dist/
RPM_FILE="$(ls -1 dist/*.rpm | tail -n 1)"

echo ""
echo "=================================================="
echo "Successfully built RPM package:"
echo "$RPM_FILE"
echo "To install on Fedora / RHEL / openSUSE:"
echo "  sudo dnf install $RPM_FILE"
echo "  (or: sudo rpm -i $RPM_FILE)"
echo "=================================================="
