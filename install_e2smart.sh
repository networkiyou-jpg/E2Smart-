
#!/bin/sh
# ==========================================================
# E2Smart v3.1.5 - Enigma2 Installer
# Developer: mouad
# Telegram: @Kingsharing1
# GitHub: networkiyou-jpg/E2Smart-
# ==========================================================

# GitHub download settings
BASE_URL="https://raw.githubusercontent.com/networkiyou-jpg/E2Smart-/main"
IPK="enigma2-plugin-extensions-e2smartbiss_3.1.5_all.ipk"
SHA256=""

PKG="enigma2-plugin-extensions-e2smartbiss"
PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/BISSManagerPRO"
TMP="/tmp/$IPK"

say() {
    echo "[E2Smart] $*"
}

die() {
    say "ERROR: $*"
    exit 1
}

# Remove option
if [ "$1" = "remove" ]; then
    command -v opkg >/dev/null 2>&1 || die "opkg not found."
    [ "$(id -u)" = "0" ] || die "Run as root."

    say "Removing E2Smart..."
    opkg remove "$PKG" || die "Removal failed."

    say "Removal completed."
    say "Restarting Enigma2..."
    sleep 2
    killall -9 enigma2
    exit 0
fi

# System checks
command -v opkg >/dev/null 2>&1 || die "Not an Enigma2 receiver."
[ "$(id -u)" = "0" ] || die "Run this installer as root."

command -v wget >/dev/null 2>&1 || command -v curl >/dev/null 2>&1 || die "wget or curl is required."

say "E2Smart installer started."

# Check free space
FREE="$(df -k / 2>/dev/null | awk 'NR==2 {print $4}')"

if [ -n "$FREE" ] && [ "$FREE" -lt 6000 ]; then
    die "Not enough free space. At least 6 MB required."
fi

# Locate existing IPK
FOUND=""

for d in /tmp /media/usb /media/hdd /media/mmc /media/usb/ipk "$(pwd)"; do
    if [ -f "$d/$IPK" ]; then
        FOUND="$d/$IPK"
        break
    fi
done

# Download IPK if not found locally
if [ -n "$FOUND" ]; then
    say "Found local package: $FOUND"

    if [ "$FOUND" != "$TMP" ]; then
        cp "$FOUND" "$TMP" || die "Cannot copy IPK to /tmp."
    fi
else
    say "Downloading E2Smart package..."

    rm -f "$TMP"

    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$TMP" "$BASE_URL/$IPK" || die "Download failed."
    else
        curl -fL -sS -o "$TMP" "$BASE_URL/$IPK" || die "Download failed."
    fi
fi

# Verify downloaded file
[ -s "$TMP" ] || die "IPK file is empty."

# Check IPK archive format
if command -v ar >/dev/null 2>&1; then
    ar t "$TMP" >/dev/null 2>&1 || die "Invalid IPK archive."
else
    say "Warning: ar command unavailable; archive format not checked."
fi

# Optional SHA256 verification
if [ -n "$SHA256" ]; then
    command -v sha256sum >/dev/null 2>&1 || die "sha256sum unavailable."

    SUM="$(sha256sum "$TMP" | awk '{print $1}')"

    [ "$SUM" = "$SHA256" ] || die "SHA256 checksum mismatch."
fi

# Install package
say "Installing E2Smart..."

if ! opkg install --force-reinstall "$TMP"; then
    opkg install --force-reinstall --force-depends "$TMP" || die "Installation failed."
fi

# Verify installation
if [ -d "$PLUGIN_DIR" ]; then
    say "E2Smart installed successfully."
else
    say "WARNING: Expected plugin directory not found."
    say "Check the actual plugin installation path."
    exit 1
fi

# Cleanup
rm -f "$TMP"

# Restart Enigma2 interface
say "Installation completed."
say "Restarting Enigma2 in 5 seconds..."
sleep 5

killall -9 enigma2

exit 0
