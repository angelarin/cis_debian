#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.7.8"
DESCRIPTION="Ensure GDM autorun-never is enabled"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
SETTING="org.gnome.desktop.media-handling autorun-never"

# --- 0. CEK APAKAH GDM TERINSTALL ---
if ! dpkg-query -s gdm3 &>/dev/null && ! dpkg-query -s gdm &>/dev/null; then
    NOTES="PASS: GDM is not installed on the system (Not Applicable)."
    echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
    exit 0
fi

# --- FUNGSI AUDIT GDM SETTINGS ---
# Tentukan pengguna GNOME yang sedang login (sesi aktif)
# Catatan: Cara ini mungkin berbeda tergantung sistem, tapi umum digunakan
TARGET_USER=$(logname 2>/dev/null || echo "vboxuser")
if [ "$TARGET_USER" = "root" ] || [ -z "$TARGET_USER" ]; then
    TARGET_USER="vboxuser" # Fallback jika tidak terdeteksi
fi

# Cari D-Bus environment (diperlukan untuk gsettings saat dijalankan sebagai root)
DBUS_ADDRESS=$(pgrep -u $TARGET_USER gnome-session | xargs -r -I{} grep -z DBUS_SESSION_BUS_ADDRESS /proc/{}/environ | sed 's/DBUS_SESSION_BUS_ADDRESS=//' | tr -d '\0')

# Jalankan gsettings sebagai target user dengan environment yang benar
if [ ! -z "$DBUS_ADDRESS" ]; then
    L_VALUE=$(sudo -u $TARGET_USER DBUS_SESSION_BUS_ADDRESS=$DBUS_ADDRESS gsettings get "$SETTING" 2>/dev/null)
else
    # Jika D-Bus tidak dapat ditemukan (misalnya sesi tidak ada), coba langsung sebagai user
    L_VALUE=$(sudo -u $TARGET_USER gsettings get "$SETTING" 2>/dev/null)
fi

if [ "$L_VALUE" = "true" ]; then
    RESULT="PASS"
    a_output+=(" - $SETTING is correctly set to true.")
else
    RESULT="FAIL"
    a_output2+=(" - $SETTING is set to $L_VALUE (should be true).")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}