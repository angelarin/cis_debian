#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.2.4"
DESCRIPTION="Ensure users must provide password for privilege escalation (no NOPASSWD globally)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
UNEXPECTED_SETTING='^[^#].*NOPASSWD'

# --- FUNGSI AUDIT NOPASSWD ---
L_OUTPUT=$(grep -r -- "$UNEXPECTED_SETTING" /etc/sudoers /etc/sudoers.d/* 2>/dev/null)

if [ -n "$L_OUTPUT" ]; then
    RESULT="FAIL"
    a_output2+=(" - Global NOPASSWD directive(s) detected (disabling password requirement). Offending lines: $L_OUTPUT")
else
    a_output+=(" - No global NOPASSWD directive(s) detected.")
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