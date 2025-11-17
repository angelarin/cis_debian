#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.4.2"
DESCRIPTION="Ensure nodev option set on /var partition"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT nodev ---
L_OUTPUT=$(findmnt -kn /var | grep -v 'nodev')

if [ -z "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=("/var mount options correctly include 'nodev'.")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    a_output2+=("/var is mounted WITHOUT the 'nodev' option. Findmnt output: $L_OUTPUT")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
# --------------------------------------------------------------------------
}