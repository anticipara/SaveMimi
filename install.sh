#!/usr/bin/env bash
# ==============================================================================
# SaveMiMi v2.3.3 — Universal Linux One-Line Installer
# ==============================================================================
# Usage:
#   curl -fsSL https://savemimi.vercel.app/install.sh | bash
#   or:
#   wget -qO- https://savemimi.vercel.app/install.sh | bash
# ==============================================================================

set -euo pipefail

APP_NAME="SaveMiMi"
APP_EXEC="savemimi"
DEFAULT_VERSION="2.3.3"
REPO="anticipara/SaveMimi"

# Auto-detect the latest release from GitHub (falls back to DEFAULT_VERSION if offline/rate-limited)
LATEST_TAG=$(curl -sSL -H "Accept: application/vnd.github+json" "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "")
if [ -n "$LATEST_TAG" ]; then
    DETECTED_VERSION="${LATEST_TAG#v}"
    if [[ "$DETECTED_VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)? ]]; then
        VERSION="${DETECTED_VERSION}"
    else
        VERSION="${DEFAULT_VERSION}"
    fi
else
    VERSION="${DEFAULT_VERSION}"
fi
BASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}"
echo "  ____                  __  __ _ __  __ _ "
echo " / ___|  __ ___   _____|  \/  (_)  \/  (_)"
echo " \___ \ / _\` \ \ / / _ \ |\/| | | |\/| | |"
echo "  ___) | (_| |\ V /  __/ |  | | | |  | | |"
echo " |____/ \__,_| \_/ \___|_|  |_|_|_|  |_|_|"
echo -e "${NC}"
echo -e "${BOLD}SaveMiMi v${VERSION} — High-Speed Download Acceleration Engine${NC}"
echo -e "Unified Rust Core • MiMiFlow Adaptive Optimization\n"

# 1. Check Architecture
ARCH="$(uname -m)"
if [ "$ARCH" != "x86_64" ]; then
    echo -e "${RED}Error: SaveMiMi currently supports x86_64 (amd64) architecture.${NC}"
    echo "Detected: ${ARCH}"
    exit 1
fi

# 2. Check Uninstall Flag
if [ "${1:-}" = "--uninstall" ] || [ "${1:-}" = "uninstall" ]; then
    echo -e "${YELLOW}Uninstalling SaveMiMi...${NC}"
    rm -f /usr/local/bin/SaveMiMi /usr/local/bin/savemimi \
          ~/.local/bin/SaveMiMi ~/.local/bin/savemimi \
          /usr/share/applications/savemimi.desktop \
          ~/.local/share/applications/savemimi.desktop \
          /usr/share/icons/hicolor/256x256/apps/savemimi.png \
          ~/.local/share/icons/hicolor/256x256/apps/savemimi.png
    update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
    echo -e "${GREEN}SaveMiMi has been completely removed from your system.${NC}"
    exit 0
fi

# 3. Determine Installation Paths
if [ "$EUID" -eq 0 ]; then
    # Running as root / sudo -> System-wide install
    BIN_DIR="/usr/local/bin"
    APP_DIR="/usr/local/lib/savemimi"
    DESKTOP_DIR="/usr/share/applications"
    ICON_DIR="/usr/share/icons/hicolor/256x256/apps"
else
    # Running as regular user -> User-local install (No password needed!)
    BIN_DIR="${HOME}/.local/bin"
    APP_DIR="${HOME}/.local/lib/savemimi"
    DESKTOP_DIR="${HOME}/.local/share/applications"
    ICON_DIR="${HOME}/.local/share/icons/hicolor/256x256/apps"
fi

mkdir -p "${BIN_DIR}" "${APP_DIR}" "${DESKTOP_DIR}" "${ICON_DIR}"

TMP_DIR="$(mktemp -d /tmp/savemimi-install-XXXXXX)"
cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo -e "${CYAN}--> Fetching SaveMiMi v${VERSION} for Linux...${NC}"

# Check if local files exist (if running from source checkout)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
LOCAL_PKG="${SCRIPT_DIR}/dist/SaveMiMi-${VERSION}-x86_64.AppImage"
LOCAL_ICON="${SCRIPT_DIR}/linux/Assets/savemimi.png"

if [ -f "${LOCAL_PKG}" ]; then
    echo "  Installing from local AppImage build..."
    cp "${LOCAL_PKG}" "${APP_DIR}/SaveMiMi.AppImage"
    chmod +x "${APP_DIR}/SaveMiMi.AppImage"
    ln -sf "${APP_DIR}/SaveMiMi.AppImage" "${BIN_DIR}/SaveMiMi"
    ln -sf "${APP_DIR}/SaveMiMi.AppImage" "${BIN_DIR}/savemimi"
elif [ -f "${SCRIPT_DIR}/dist/app/SaveMiMi" ]; then
    echo "  Installing from local published application..."
    cp -r "${SCRIPT_DIR}/dist/app/"* "${APP_DIR}/"
    chmod +x "${APP_DIR}/SaveMiMi"
    ln -sf "${APP_DIR}/SaveMiMi" "${BIN_DIR}/SaveMiMi"
    ln -sf "${APP_DIR}/SaveMiMi" "${BIN_DIR}/savemimi"
elif [ -f "${SCRIPT_DIR}/dist/savemimi" ]; then
    echo "  Installing local CLI executable..."
    cp "${SCRIPT_DIR}/dist/savemimi" "${BIN_DIR}/savemimi"
    chmod +x "${BIN_DIR}/savemimi"
else
    # Download AppImage from GitHub Releases
    DOWNLOAD_URL="${BASE_URL}/SaveMiMi-${VERSION}-x86_64.AppImage"
    echo "  Downloading from: ${DOWNLOAD_URL}"
    TMP_PKG="${TMP_DIR}/SaveMiMi.AppImage"

    if command -v curl &>/dev/null; then
        curl -fSL --progress-bar -o "${TMP_PKG}" "${DOWNLOAD_URL}" || {
            echo -e "${YELLOW}Notice: Online release package not found yet. Build locally or publish GitHub release.${NC}"
        }
    elif command -v wget &>/dev/null; then
        wget -q --show-progress -O "${TMP_PKG}" "${DOWNLOAD_URL}" || true
    fi

    if [ -f "${TMP_PKG}" ] && [ -s "${TMP_PKG}" ]; then
        mv -f "${TMP_PKG}" "${APP_DIR}/SaveMiMi.AppImage"
        chmod 755 "${APP_DIR}/SaveMiMi.AppImage"
        ln -sf "${APP_DIR}/SaveMiMi.AppImage" "${BIN_DIR}/SaveMiMi"
        ln -sf "${APP_DIR}/SaveMiMi.AppImage" "${BIN_DIR}/savemimi"
    fi
fi

# 4. Install High-Resolution App Icon
echo -e "${CYAN}--> Installing application icon...${NC}"
if [ -f "${LOCAL_ICON}" ]; then
    cp "${LOCAL_ICON}" "${ICON_DIR}/savemimi.png"
elif [ -f "${SCRIPT_DIR}/StorePackage/Assets/Square44x44Logo.targetsize-256.png" ]; then
    cp "${SCRIPT_DIR}/StorePackage/Assets/Square44x44Logo.targetsize-256.png" "${ICON_DIR}/savemimi.png"
else
    # Download official icon from repository
    ICON_URL="https://raw.githubusercontent.com/${REPO}/main/StorePackage/Assets/Square44x44Logo.targetsize-256.png"
    curl -fsSL -o "${ICON_DIR}/savemimi.png" "${ICON_URL}" 2>/dev/null || true
fi

# 5. Create Desktop Entry (Directly Adds to App Drawer)
echo -e "${CYAN}--> Adding to application drawer...${NC}"
cat <<EOF > "${DESKTOP_DIR}/savemimi.desktop"
[Desktop Entry]
Name=SaveMiMi
GenericName=Download Manager
Comment=SaveMiMi v2.3.3 High-Speed Acceleration Engine
Exec="${BIN_DIR}/SaveMiMi" %U
Icon=savemimi
Terminal=false
Type=Application
Categories=Network;FileTransfer;Utility;
MimeType=x-scheme-handler/savemimi;
StartupNotify=true
StartupWMClass=SaveMiMi
Actions=NewDownload;

[Desktop Action NewDownload]
Name=New Download
Exec="${BIN_DIR}/SaveMiMi" --add
EOF

chmod 644 "${DESKTOP_DIR}/savemimi.desktop"

# 6. Refresh Linux Desktop Database
echo -e "${CYAN}--> Updating desktop database...${NC}"
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
fi

if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$(dirname "${ICON_DIR}")/.." 2>/dev/null || true
fi

# 7. Check PATH if user local install
if [ "$EUID" -ne 0 ]; then
    if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
        echo -e "${YELLOW}Note: Add ~/.local/bin to your PATH to run 'savemimi' directly from any terminal:${NC}"
        echo '  echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.bashrc'
    fi
fi

echo -e "\n${GREEN}${BOLD}✓ Installation Successful!${NC}"
echo -e "SaveMiMi v${VERSION} is now installed and available in your ${BOLD}App Drawer${NC} with its official logo."
echo -e "You can launch it from your desktop menu or by running: ${CYAN}savemimi${NC}\n"
