#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.2.2"
DESCRIPTION="Ensure audit logs are not automatically deleted"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
CONFIG_FILE="/etc/audit/auditd.conf"
SETTING="max_log_file_action"
EXPECTED_VALUE="keep_logs"

# --- FUNGSI AUDIT LOG RETENTION ---
L_OUTPUT=$(grep "$SETTING" "$CONFIG_FILE" 2>/dev/null | tail -n 1)
L_VALUE=$(echo "$L_OUTPUT" | awk '{print $NF}' | xargs)

if [ "$L_VALUE" = "$EXPECTED_VALUE" ]; then
    a_output+=(" - $SETTING is correctly set to $EXPECTED_VALUE.")
    a_output+=(" - Detected line: $L_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - $SETTING is set to $L_VALUE (Expected: $EXPECTED_VALUE).")
    [ -n "$L_OUTPUT" ] && a_output+=(" - Detected line: $L_OUTPUT")
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