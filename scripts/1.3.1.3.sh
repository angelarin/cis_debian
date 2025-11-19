#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.3.1.3"
DESCRIPTION="Ensure all AppArmor Profiles are in enforce or complain mode"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT PROFILES ---
# Ambil seluruh output untuk referensi INFO
L_STATUS=$(apparmor_status 2>/dev/null)
L_OUTPUT_PROFILES=$(echo "$L_STATUS" | grep profiles)
L_OUTPUT_PROCESSES=$(echo "$L_STATUS" | grep processes)

if [ -z "$L_STATUS" ]; then
    a_output2+=(" - Failed to run apparmor_status. AppArmor may not be active or installed.")
else
    # 1. Cek mode profil (memastikan 0 profiles are unconfined)
    # Targetkan frasa: "profiles are in unconfined mode."
    # Menggunakan nilai default 0 jika grep tidak menemukan apa-apa (untuk menghindari error integer)
    UNCONFINED_PROFILES=$(echo "$L_STATUS" | grep 'profiles are in unconfined mode' | awk '{print $1}')
    UNCONFINED_PROFILES=${UNCONFINED_PROFILES:-0} # Setel ke 0 jika kosong

    if [ "$UNCONFINED_PROFILES" -eq 0 ]; then
        a_output+=(" - All loaded profiles are in enforce or complain mode (0 unconfined).")
    else
        a_output2+=(" - $UNCONFINED_PROFILES profiles are unconfined.")
    fi
    a_output+=(" - Profile Status: $L_OUTPUT_PROFILES")

    # 2. Cek proses (memastikan 0 processes are unconfined)
    # Targetkan frasa: "processes are unconfined but have a profile defined."
    UNCONFINED_PROCESSES=$(echo "$L_STATUS" | grep 'processes are unconfined but have a profile defined' | awk '{print $1}')
    UNCONFINED_PROCESSES=${UNCONFINED_PROCESSES:-0} # Setel ke 0 jika kosong
    
    if [ "$UNCONFINED_PROCESSES" -eq 0 ]; then
        a_output+=(" - All processes with defined profiles are confined (0 unconfined but profiled).")
    else
        a_output2+=(" - $UNCONFINED_PROCESSES processes are unconfined but have a profile defined.")
    fi
    a_output+=(" - Process Status: $L_OUTPUT_PROCESSES")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}