#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.21"
DESCRIPTION="Ensure the running and on disk configuration is the same (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
COMMAND="augenrules --check"
EXPECTED_OUTPUT="No change"

# --- FUNGSI AUDIT AUGENRULES CHECK ---
L_OUTPUT=$($COMMAND 2>&1)
L_EXIT_CODE=$?

if [ $L_EXIT_CODE -eq 0 ]; then
    if echo "$L_OUTPUT" | grep -q "$EXPECTED_OUTPUT"; then
        a_output+=(" - $COMMAND completed successfully. Output: $L_OUTPUT")
        a_output+=(" - The rules on disk and the merged file appear to be synchronized ('$EXPECTED_OUTPUT' returned).")
        RESULT="PASS"
    else
        # Jika exit code 0 tapi output tidak 'No change' (misal, ada warning lain)
        a_output2+=(" - $COMMAND completed, but rules appear to be different (Output suggests drift). Output: $L_OUTPUT")
        a_output2+=(" - Remediasi: Run 'augenrules --load' (requires root/sudo).")
        RESULT="FAIL"
    fi
else
    # Jika exit code non-0 (misal, error atau drift parah)
    a_output2+=(" - $COMMAND failed to execute or returned a non-zero exit code ($L_EXIT_CODE). Check auditd package/status.")
    a_output2+=(" - Full Output: $L_OUTPUT")
    RESULT="FAIL"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "FAIL" ]; then
    NOTES+="FAIL: Configuration drift detected or check failed. ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
else
    NOTES+="PASS: Configuration is synchronized. ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}