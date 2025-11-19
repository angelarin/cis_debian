#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.14"
DESCRIPTION="Ensure sshd LogLevel is configured (VERBOSE or INFO)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SETTING="LogLevel"
EXPECTED_VALUES=("VERBOSE" "INFO")

# --- FUNGSI AUDIT LOG LEVEL ---
L_OUTPUT=$(sshd -T 2>/dev/null | grep -i "$SETTING")
L_VALUE=$(echo "$L_OUTPUT" | awk '{print $2}' | xargs | tr '[:lower:]' '[:upper:]')

if [ -z "$L_VALUE" ]; then
    RESULT="FAIL"
    a_output2+=(" - $SETTING is NOT set.")
elif [[ " ${EXPECTED_VALUES[*]} " =~ " ${L_VALUE} " ]]; then
    a_output+=(" - $SETTING is correctly set to $L_VALUE.")
    a_output+=(" - Detected setting: $L_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - $SETTING is set to $L_VALUE (Expected: VERBOSE or INFO).")
    a_output+=(" - Detected setting: $L_OUTPUT")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}