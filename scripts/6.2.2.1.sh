#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.2.1"
DESCRIPTION="Ensure audit log storage size is configured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
CONFIG_FILE="/etc/audit/auditd.conf"
SETTING="max_log_file"

# --- FUNGSI AUDIT MAX LOG FILE ---
L_OUTPUT=$(grep -Po -- '^\h*max_log_file\h*=\h*\d+\b' "$CONFIG_FILE" 2>/dev/null | tail -n 1)
L_VALUE=$(echo "$L_OUTPUT" | awk '{print $NF}' | xargs)

if [ -n "$L_OUTPUT" ]; then
    a_output+=(" - $SETTING is configured. Value: $L_VALUE MB.")
    a_output+=(" - Detected line: $L_OUTPUT")
    RESULT="REVIEW" # Nilai harus diverifikasi secara manual terhadap kebijakan situs
else
    RESULT="FAIL"
    a_output2+=(" - $SETTING is NOT configured in $CONFIG_FILE.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "REVIEW" ]; then
    NOTES+="REVIEW: $SETTING found. ${a_output[*]}"
    NOTES+=" | Action: REVIEW the size ($L_VALUE MB) against local site policy for sufficiency."
elif [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}