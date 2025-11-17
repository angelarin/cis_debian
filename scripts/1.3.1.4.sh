#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.3.1.4"
DESCRIPTION="Ensure all AppArmor Profiles are enforcing"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT PROFILES (ENFORCING ONLY) ---
L_OUTPUT_PROFILES=$(apparmor_status 2>/dev/null | grep profiles)
L_OUTPUT_PROCESSES=$(apparmor_status 2>/dev/null | grep processes)

if [ -z "$L_OUTPUT_PROFILES" ] || [ -z "$L_OUTPUT_PROCESSES" ]; then
    a_output2+=(" - Failed to run apparmor_status. AppArmor may not be active or installed.")
else
    # 1. Cek mode complain (harus 0)
    COMPLAIN_PROFILES=$(echo "$L_OUTPUT_PROFILES" | grep 'profiles are in complain mode' | awk '{print $1}')
    if [ "$COMPLAIN_PROFILES" -eq 0 ]; then
        a_output+=(" - All loaded profiles are in enforce mode (0 in complain mode).")
    else
        a_output2+=(" - $COMPLAIN_PROFILES profiles are still in complain mode. They should be enforced.")
    fi
    a_output+=(" - Profile Status: $L_OUTPUT_PROFILES")

    # 2. Cek proses dalam mode complain (harus 0)
    COMPLAIN_PROCESSES=$(echo "$L_OUTPUT_PROCESSES" | grep 'processes are in complain mode' | awk '{print $1}')
    if [ "$COMPLAIN_PROCESSES" -eq 0 ]; then
        a_output+=(" - All confined processes are in enforce mode (0 in complain mode).")
    else
        a_output2+=(" - $COMPLAIN_PROCESSES processes are still in complain mode.")
    fi
    a_output+=(" - Process Status: $L_OUTPUT_PROCESSES")

    # 3. Cek unconfined (harus 0, ini diulang dari 1.3.1.3 untuk kelengkapan)
    UNCONFINED_PROCESSES=$(echo "$L_OUTPUT_PROCESSES" | grep 'processes are unconfined' | awk '{print $1}')
    if [ "$UNCONFINED_PROCESSES" -ne 0 ]; then
        a_output2+=(" - $UNCONFINED_PROCESSES processes are unconfined.")
    fi
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