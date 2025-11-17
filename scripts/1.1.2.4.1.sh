#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.4.1"
DESCRIPTION="Ensure separate partition exists for /var"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT /var MOUNT STATUS ---
L_OUTPUT=$(findmnt -kn /var)

if [ -n "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=("/var is currently mounted. Findmnt output: $L_OUTPUT")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    a_output2+=("/var is NOT mounted.")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
# --------------------------------------------------------------------------
}