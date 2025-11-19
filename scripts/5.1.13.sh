#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.13"
DESCRIPTION="Ensure sshd LoginGraceTime is configured (1 to 60 seconds)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SETTING="LoginGraceTime"
MIN_VAL=1
MAX_VAL=60

# --- FUNGSI AUDIT LOGIN GRACE TIME ---
L_OUTPUT=$(sshd -T 2>/dev/null | grep -i "$SETTING")
L_VALUE=$(echo "$L_OUTPUT" | awk '{print $2}' | xargs)

if [ -z "$L_VALUE" ]; then
    RESULT="FAIL"
    a_output2+=(" - $SETTING is NOT set.")
elif ! [[ "$L_VALUE" =~ ^[0-9]+$ ]]; then
    RESULT="FAIL"
    a_output2+=(" - $SETTING value is non-numeric (Value: $L_VALUE).")
elif [ "$L_VALUE" -ge "$MIN_VAL" ] && [ "$L_VALUE" -le "$MAX_VAL" ]; then
    a_output+=(" - $SETTING is correctly set between $MIN_VAL and $MAX_VAL seconds (Value: $L_VALUE).")
    a_output+=(" - Detected setting: $L_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - $SETTING is set to $L_VALUE (Outside of range $MIN_VAL to $MAX_VAL seconds).")
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