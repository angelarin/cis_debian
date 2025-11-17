#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.6.1"
DESCRIPTION="Ensure separate partition exists for /var/log (Automated)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
TARGET="/var/log"

# --- FUNGSI AUDIT MOUNT STATUS ---
L_OUTPUT=$(findmnt -kn $TARGET)

if [ -n "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=("$TARGET is currently mounted. Findmnt output: $L_OUTPUT")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    a_output2+=("$TARGET is NOT mounted.")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}