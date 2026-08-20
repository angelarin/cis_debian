#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
# [UBAH-1] Sesuaikan CHECK_ID, DESCRIPTION, PATH_TARGET, dan OPTION_TARGET
CHECK_ID="1.1.2.5.3"
DESCRIPTION="Ensure nosuid option set on /var/tmp partition"
TARGET_MOUNT="/var/tmp"
TARGET_OPT="nosuid"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# [TAMBAH-1] Validasi Running Mount: Wajib pakai flag -M dan cek ketersediaan partisi
L_RUNNING=$(findmnt -kn -M "$TARGET_MOUNT" 2>/dev/null)

if [ -z "$L_RUNNING" ]; then
    RESULT="FAIL"
    a_output2+=(" - Running: $TARGET_MOUNT is not mounted as a separate partition.")
else
    # [TAMBAH-2] Cek apakah opsi target terpasang pada mount aktif
    if echo "$L_RUNNING" | grep -Pq "\b$TARGET_OPT\b"; then
        a_output+=(" - Running: $TARGET_OPT option is set on $TARGET_MOUNT mount.")
    else
        RESULT="FAIL"
        a_output2+=(" - Running: $TARGET_OPT option is NOT set on $TARGET_MOUNT mount.")
    fi
fi

# [TAMBAH-3] Validasi Persisten: Cek file /etc/fstab untuk partisi target
L_FSTAB=$(grep -P "^\h*[^#\n\r\h]+\h+\\${TARGET_MOUNT}\b" /etc/fstab 2>/dev/null)

if [ -z "$L_FSTAB" ]; then
    RESULT="FAIL"
    a_output2+=(" - Persistent: $TARGET_MOUNT is NOT configured in /etc/fstab.")
else
    # [TAMBAH-4] Cek apakah opsi target terdaftar di /etc/fstab
    if echo "$L_FSTAB" | grep -Pq "\b$TARGET_OPT\b"; then
        a_output+=(" - Persistent: $TARGET_OPT option is configured in /etc/fstab.")
    else
        RESULT="FAIL"
        a_output2+=(" - Persistent: $TARGET_OPT option is NOT configured in /etc/fstab.")
    fi
fi

# [UBAH-2] Ganti logika output master script agar menangani status PASS & FAIL secara akurat
if [ "$RESULT" = "PASS" ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}