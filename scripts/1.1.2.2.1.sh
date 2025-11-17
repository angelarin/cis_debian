#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.2.1"
DESCRIPTION="Ensure /dev/shm is a separate partition"
# -----------------------------------------------------

{
a_output=()     # Untuk kondisi yang BENAR (PASS)
a_output2=()    # Untuk kondisi yang SALAH (FAIL)
RESULT=""
NOTES=""

# --- FUNGSI AUDIT /dev/shm MOUNT STATUS ---
L_OUTPUT=$(findmnt -kn /dev/shm)

if [ -n "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=("/dev/shm is currently mounted. Findmnt output: $L_OUTPUT")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    a_output2+=("/dev/shm is NOT mounted.")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
# --------------------------------------------------------------------------
}