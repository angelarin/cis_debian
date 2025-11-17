#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.3.1.3"
DESCRIPTION="Ensure all AppArmor Profiles are in enforce or complain mode"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT PROFILES ---
L_OUTPUT_PROFILES=$(apparmor_status 2>/dev/null | grep profiles)
L_OUTPUT_PROCESSES=$(apparmor_status 2>/dev/null | grep processes)

if [ -z "$L_OUTPUT_PROFILES" ] || [ -z "$L_OUTPUT_PROCESSES" ]; then
    a_output2+=(" - Failed to run apparmor_status. AppArmor may not be active or installed.")
else
    # 1. Cek mode profil (memastikan 0 profiles are unconfined)
    UNCONFINED_PROFILES=$(echo "$L_OUTPUT_PROFILES" | grep 'profiles are unconfined' | awk '{print $1}')
    if [ "$UNCONFINED_PROFILES" -eq 0 ]; then
        a_output+=(" - All loaded profiles are in enforce or complain mode.")
    else
        a_output2+=(" - $UNCONFINED_PROFILES profiles are unconfined.")
    fi
    a_output+=(" - Profile Status: $L_OUTPUT_PROFILES")

    # 2. Cek proses (memastikan 0 processes are unconfined)
    UNCONFINED_PROCESSES=$(echo "$L_OUTPUT_PROCESSES" | grep 'processes are unconfined' | awk '{print $1}')
    if [ "$UNCONFINED_PROCESSES" -eq 0 ]; then
        a_output+=(" - All processes with defined profiles are confined (0 unconfined).")
    else
        a_output2+=(" - $UNCONFINED_PROCESSES processes are unconfined.")
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