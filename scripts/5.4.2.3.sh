#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.2.3"
DESCRIPTION="Ensure group root is the only GID 0 group"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
GROUP_FILE="/etc/group"
EXPECTED_GROUP="root"

# --- FUNGSI AUDIT GID 0 ---
L_OUTPUT=$(awk -F: '$3=="0"{print $1}' "$GROUP_FILE" 2>/dev/null)
L_COUNT=$(echo "$L_OUTPUT" | wc -l)

if [ "$L_COUNT" -eq 1 ] && [ "$L_OUTPUT" = "$EXPECTED_GROUP" ]; then
    a_output+=(" - Only group '$EXPECTED_GROUP' has GID 0 (PASS).")
else
    RESULT="FAIL"
    a_output2+=(" - Multiple groups or non-root groups found with GID 0.")
    a_output2+=(" - Detected GID 0 groups: $L_OUTPUT")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}