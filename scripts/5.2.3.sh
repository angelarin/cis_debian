#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.2.3"
DESCRIPTION="Ensure sudo log file exists (logfile is set)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
EXPECTED_SETTING="^\h*Defaults\h+([^#]+,\h*)?logfile\h*=\h*(\"|\')?\H+(\"|\')?(,\h*\H+\h*)*\h*(#.*)?$"

# --- FUNGSI AUDIT LOGFILE ---
L_OUTPUT=$(grep -rPsi -- "$EXPECTED_SETTING" /etc/sudoers /etc/sudoers.d/* 2>/dev/null)

if [ -n "$L_OUTPUT" ]; then
    a_output+=(" - Defaults logfile is configured.")
    a_output+=(" - Detected lines: $L_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - Defaults logfile is NOT explicitly configured.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set/Info: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}