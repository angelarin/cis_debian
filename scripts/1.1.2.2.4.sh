#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.2.4"
DESCRIPTION="Ensure noexec option set on /dev/shm partition"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT noexec ---
L_OUTPUT=$(findmnt -kn /dev/shm | grep -v 'noexec')

if [ -z "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=("/dev/shm mount options correctly include 'noexec'.")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    a_output2+=("/dev/shm is mounted WITHOUT the 'noexec' option. Findmnt output: $L_OUTPUT")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
# --------------------------------------------------------------------------
}