#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.2.3"
DESCRIPTION="Ensure nosuid option set on /dev/shm partition"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT nosuid ---
L_OUTPUT=$(findmnt -kn /dev/shm | grep -v 'nosuid')

if [ -z "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=("/dev/shm mount options correctly include 'nosuid'.")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    a_output2+=("/dev/shm is mounted WITHOUT the 'nosuid' option. Findmnt output: $L_OUTPUT")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
# --------------------------------------------------------------------------
}