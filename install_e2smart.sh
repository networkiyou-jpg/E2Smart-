#!/bin/sh
# E2Smart installer for Enigma2 receivers (OpenATV and similar). Run it from Telnet/SSH:
#   wget -q -O - https://raw.githubusercontent.com/networkiyou-jpg/E2Smart-/main/install_e2smart.sh | sh
# or copy this file and the .ipk to /tmp and run:  sh /tmp/install_e2smart.sh
# Developer: mouad - Telegram @Kingsharing1

# ====== GitHub address of the IPK (same folder as this script) ======
BASE_URL="https://raw.githubusercontent.com/networkiyou-jpg/E2Smart-/main"
IPK="enigma2-plugin-extensions-e2smartbiss_3.1.5_all.ipk"
SHA256=""        # optional: sha256 of the IPK (sha256sum file.ipk); empty = no check
# =====================================================================

PKG="enigma2-plugin-extensions-e2smartbiss"
TMP="/tmp/$IPK"

say() { echo "[E2Smart] $*"; }
die() { echo "[E2Smart] ERROR: $*"; exit 1; }

if [ "$1" = "remove" ]; then
    say "Removing E2Smart (your settings are kept) ..."
    opkg remove "$PKG" || die "remove failed"
    say "Done. Restarting the interface ..."
    sleep 2; killall -9 enigma2
    exit 0
fi

command -v opkg >/dev/null 2>&1 || die "opkg not found: this is not an Enigma2 image."
[ "$(id -u)" = "0" ] || die "run as root."

# 1) get the IPK: already next to the script / in /tmp / USB, else download it
FOUND=""
for d in /tmp /media/usb /media/hdd /media/mmc /media/usb/ipk "$(pwd)"; do
    [ -f "$d/$IPK" ] && FOUND="$d/$IPK" && break
done
if [ -n "$FOUND" ]; then
    say "Found $FOUND"
    [ "$FOUND" = "$TMP" ] || cp "$FOUND" "$TMP" || die "cannot copy the file to /tmp"
else
    say "Downloading $IPK ..."
    rm -f "$TMP"
    wget -q -O "$TMP" "$BASE_URL/$IPK" 2>/dev/null || wget -q --no-check-certificate -O "$TMP" "$BASE_URL/$IPK" 2>/dev/null \
        || curl -fsS -o "$TMP" "$BASE_URL/$IPK" 2>/dev/null || die "download failed. Check the internet connection."
fi
[ -s "$TMP" ] || die "the file is empty."

# 2) integrity
if [ -n "$SHA256" ]; then
    SUM="$(sha256sum "$TMP" 2>/dev/null | cut -d' ' -f1)"
    [ "$SUM" = "$SHA256" ] || die "the file is damaged (checksum mismatch). Run the command again."
fi

# 3) free space (needs about 5 MB)
FREE="$(df -k / 2>/dev/null | awk 'NR==2 {print $4}')"
[ -n "$FREE" ] && [ "$FREE" -lt 6000 ] && die "not enough free space on the receiver (need ~6 MB)."

# 4) install (upgrades in place; settings are kept)
say "Installing ..."
opkg install --force-reinstall "$TMP" || opkg install --force-reinstall --force-depends "$TMP" || die "installation failed."
rm -f "$TMP"

if [ -d /usr/lib/enigma2/python/Plugins/Extensions/BISSManagerPRO ]; then
    say "Installed OK."
else
    die "installed, but the plugin folder was not found."
fi

say "Restarting the interface in 3 seconds ... (then open: Menu > Plugins > E2Smart)"
sleep 3
killall -9 enigma2
