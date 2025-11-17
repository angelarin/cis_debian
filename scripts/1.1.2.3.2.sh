#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.3.2"
DESCRIPTION="Ensure nodev option set on /home partition"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT nodev ---
L_OUTPUT=$(findmnt -kn /home | grep -v 'nodev')

if [ -z "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=("/home mount options correctly include 'nodev'.")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    a_output2+=("/home is mounted WITHOUT the 'nodev' option. Findmnt output: $L_OUTPUT")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
# --------------------------------------------------------------------------
}