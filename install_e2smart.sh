#!/bin/sh
# ==========================================================
# E2Smart Installer for Enigma2
# Compatible with OpenATV and similar Enigma2 images
# Developer: mouad - Telegram @Kingsharing1
# ==========================================================

BASE_URL="https://raw.githubusercontent.com/networkiyou-jpg/E2Smart-/main"
IPK="enigma2-plugin-extensions-e2smartbiss_3.1.5_all.ipk"
SHA256=""

PKG="enigma2-plugin-extensions-e2smartbiss"
TMP="/tmp/$IPK"

say() {
    echo "[E2Smart] $*"
}

die() {
    say "ERROR: $*"
    exit 1
}

# ----------------------------------------------------------
# REMOVE
# ----------------------------------------------------------
if [ "$1" = "remove" ]; then
    command -v opkg >/dev/null 2>&1 || die "opkg not found."
    [ "$(id -u)" = "0" ] || die "Run as root."

    say "Removing E2Smart..."
    opkg remove "$PKG" || die "Removal failed."

    say "E2Smart removed successfully."
    say "Restarting Enigma2..."
    sleep 2
    killall -9 enigma2 2>/dev/null
    exit 0
fi

# ----------------------------------------------------------
# SYSTEM CHECKS
# ----------------------------------------------------------
command -v opkg >/dev/null 2>&1 || die "This is not a supported Enigma2 image."
[ "$(id -u)" = "0" ] || die "Please run as root."

if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
    die "Neither wget nor curl is installed."
fi

# ----------------------------------------------------------
# CHECK FREE SPACE
# ----------------------------------------------------------
FREE="$(df -k / 2>/dev/null | awk 'NR==2 {print $4}')"

if [ -n "$FREE" ] && [ "$FREE" -lt 6000 ]; then
    die "Not enough free space. At least 6 MB is recommended."
fi

# ----------------------------------------------------------
# FIND LOCAL IPK OR DOWNLOAD FROM GITHUB
# ----------------------------------------------------------
FOUND=""

for d in /tmp /media/usb /media/hdd /media/mmc /media/usb/ipk "$(pwd)"; do
    if [ -f "$d/$IPK" ]; then
        FOUND="$d/$IPK"
        break
    fi
done

if [ -n "$FOUND" ]; then
    say "Found local package: $FOUND"

    if [ "$FOUND" != "$TMP" ]; then
        cp "$FOUND" "$TMP" || die "Cannot copy package to /tmp."
    fi
else
    say "Downloading E2Smart package from GitHub..."

    rm -f "$TMP"

    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$TMP" "$BASE_URL/$IPK" ||
        wget -q --no-check-certificate -O "$TMP" "$BASE_URL/$IPK" ||
        die "Download failed. Check internet connection and GitHub file."
    else
        curl -fsSL -o "$TMP" "$BASE_URL/$IPK" ||
        die "Download failed. Check internet connection and GitHub file."
    fi
fi

[ -s "$TMP" ] || die "Downloaded IPK is empty or missing."

# ----------------------------------------------------------
# OPTIONAL SHA256 CHECK
# ----------------------------------------------------------
if [ -n "$SHA256" ]; then
    command -v sha256sum >/dev/null 2>&1 || die "sha256sum is not available."

    SUM="$(sha256sum "$TMP" | awk '{print $1}')"

    [ "$SUM" = "$SHA256" ] ||
        die "SHA256 verification failed. Package may be damaged."
fi

# ----------------------------------------------------------
# INSTALL PACKAGE
# ----------------------------------------------------------
say "Installing E2Smart..."

if ! opkg install --force-reinstall "$TMP"; then
    rm -f "$TMP"
    die "Installation failed. Check the missing dependencies shown above."
fi

rm -f "$TMP"

# ----------------------------------------------------------
# VERIFY PACKAGE INSTALLATION
# ----------------------------------------------------------
if opkg status "$PKG" 2>/dev/null | grep -q "Status: install"; then
    say "E2Smart package installed successfully."
else
    die "Package installation could not be verified."
fi

# ----------------------------------------------------------
# RESTART ENIGMA2
# ----------------------------------------------------------
say "Installation completed."
say "E2Smart should now be available under:"
say "Menu > Plugins > E2Smart"
say "Restarting Enigma2 in 5 seconds..."

sleep 5
killall -9 enigma2 2>/dev/null

exit 0
