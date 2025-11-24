#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.2.6"
DESCRIPTION="Ensure sudo authentication timeout is configured correctly (<= 15 minutes)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
MAX_TIMEOUT=15 # Minutes
# MAX_TIMEOUT_SEC=900 # Tidak digunakan, kita fokus pada nilai menit

# 1. Cek konfigurasi timestamp_timeout di sudoers*
# Mencari semua nilai yang dikonfigurasi, termasuk -1
L_CONFIGURED_TIMEOUT=$(grep -roP "timestamp_timeout=\K-?[0-9]*" /etc/sudoers /etc/sudoers.d/* 2>/dev/null | sort -n | tail -n 1)

if [ -n "$L_CONFIGURED_TIMEOUT" ]; then
    L_VALUE=$L_CONFIGURED_TIMEOUT
    a_output+=(" - Configured timestamp_timeout value found: $L_VALUE minutes.")
    
    # --- LOGIKA PENILAIAN JIKA KONFIGURASI ADA ---
    if [ "$L_VALUE" -eq -1 ]; then
        RESULT="FAIL"
        a_output2+=(" - timestamp_timeout is set to -1 (disabled/infinite timeout).")
        NOTES_REMEDIATION="Untuk remediasi, edit file sudoers dan ubah menjadi: Defaults timestamp_timeout=$MAX_TIMEOUT"
    elif [ "$L_VALUE" -gt "$MAX_TIMEOUT" ]; then
        RESULT="FAIL"
        a_output2+=(" - timestamp_timeout is set to $L_VALUE minutes (Greater than $MAX_TIMEOUT minutes).")
        NOTES_REMEDIATION="Untuk remediasi, edit file sudoers dan ubah nilai timeout menjadi $MAX_TIMEOUT menit atau kurang."
    else
        a_output+=(" - timestamp_timeout is set to $L_VALUE minutes (<= $MAX_TIMEOUT minutes).")
    fi
else
    # 2. LOGIKA BARU: Jika TIDAK ADA konfigurasi eksplisit, maka FAIL.
    # Meskipun default-nya mungkin 15 menit (900 detik), audit ini MENGHARUSKAN konfigurasi eksplisit.
    
    L_DEFAULT_TIMEOUT_RAW=$(sudo -V 2>/dev/null | grep "Authentication timestamp timeout:")
    L_DEFAULT_TIMEOUT_DISPLAY=$(echo "$L_DEFAULT_TIMEOUT_RAW" | sed 's/Authentication timestamp timeout: //')
    
    RESULT="FAIL"
    a_output2+=(" - timestamp_timeout is NOT explicitly configured in /etc/sudoers or /etc/sudoers.d/.")
    a_output+=(" - System default timeout: $L_DEFAULT_TIMEOUT_DISPLAY.")
    NOTES_REMEDIATION="Untuk remediasi, tambahkan baris 'Defaults timestamp_timeout=$MAX_TIMEOUT' ke /etc/sudoers menggunakan 'sudo visudo'."
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" = "PASS" ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    
    # Tambahkan informasi (default/lainnya) jika ada
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
    
    # Tambahkan Remediasi
    NOTES+=" | Remediasi: $NOTES_REMEDIATION"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"

}