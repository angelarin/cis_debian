#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.3.2"
DESCRIPTION="Ensure nodev option set on /home partition"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# 1. Cek Running Mount Point (Wajib menggunakan -M agar tidak fallback ke '/')
L_RUNNING=$(findmnt -kn -M /home 2>/dev/null)

if [ -z "$L_RUNNING" ]; then
    RESULT="FAIL"
    a_output2+=(" - Running: /home is not mounted as a separate partition.")
else
    # Cek apakah opsi nodev ada pada mount aktif
    if echo "$L_RUNNING" | grep -Pq '\bnodev\b'; then
        a_output+=(" - Running: nodev option is set on /home mount.")
    else
        RESULT="FAIL"
        a_output2+=(" - Running: nodev option is NOT set on /home mount.")
    fi
fi

# 2. Cek Konfigurasi Persisten di /etc/fstab
L_FSTAB=$(grep -P '^\h*[^#\n\r\h]+\h+\/home\b' /etc/fstab 2>/dev/null)

if [ -z "$L_FSTAB" ]; then
    RESULT="FAIL"
    a_output2+=(" - Persistent: /home is NOT configured in /etc/fstab.")
else
    if echo "$L_FSTAB" | grep -Pq '\bnodev\b'; then
        a_output+=(" - Persistent: nodev option is configured in /etc/fstab.")
    else
        RESULT="FAIL"
        a_output2+=(" - Persistent: nodev option is NOT configured in /etc/fstab.")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" = "PASS" ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}