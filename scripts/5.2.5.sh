#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.2.5"
DESCRIPTION="Ensure re-authentication for privilege escalation is not disabled globally (no !authenticate)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
UNEXPECTED_SETTING='^[^#].*\!authenticate'

# --- FUNGSI AUDIT !AUTHENTICATE ---
L_OUTPUT=$(grep -r -- "$UNEXPECTED_SETTING" /etc/sudoers /etc/sudoers.d/* 2>/dev/null)

if [ -n "$L_OUTPUT" ]; then
    RESULT="FAIL"
    a_output2+=(" - Global !authenticate directive(s) detected (disabling re-authentication). Offending lines: $L_OUTPUT")
else
    a_output+=(" - No global !authenticate directive(s) detected.")
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