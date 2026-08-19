#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.8"
DESCRIPTION="Ensure sshd DisableForwarding is enabled"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
SETTING="DisableForwarding"
EXPECTED_VALUE="yes"

# --- FUNGSI AUDIT DISABLE FORWARDING ---
L_OUTPUT=$(sshd -T 2>/dev/null | grep -Pi -- "$SETTING")
L_VALUE=$(echo "$L_OUTPUT" | awk '{print $2}' | xargs)

if [ "$L_VALUE" = "$EXPECTED_VALUE" ]; then
    RESULT="PASS"
    a_output+=(" - $SETTING is correctly set to $EXPECTED_VALUE.")
    a_output+=(" - Detected setting: $L_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - $SETTING is set to $L_VALUE (Expected: $EXPECTED_VALUE).")
    [ -n "$L_OUTPUT" ] && a_output+=(" - Detected setting: $L_OUTPUT")
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