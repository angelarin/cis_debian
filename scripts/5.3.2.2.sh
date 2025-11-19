#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.2.2"
DESCRIPTION="Ensure pam_faillock module is enabled"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="FAIL" NOTES=""
TARGET_MODULE="pam_faillock\.so"
TARGET_FILES="/etc/pam.d/common-auth /etc/pam.d/common-account"
EXPECTED_MIN_COUNT=3 # Biasanya 2 di common-auth, 1 di common-account

# --- FUNGSI AUDIT PAM FAILLOCK ---
L_OUTPUT=$(grep -P -- "\b$TARGET_MODULE\b" $TARGET_FILES 2>/dev/null)
L_COUNT=$(echo "$L_OUTPUT" | grep -c "\b$TARGET_MODULE\b")

if [ "$L_COUNT" -ge "$EXPECTED_MIN_COUNT" ]; then
    RESULT="PASS"
    a_output+=(" - $TARGET_MODULE is enabled (found $L_COUNT entries, expected min $EXPECTED_MIN_COUNT).")
    a_output+=(" - Detected lines: ${L_OUTPUT//$'\n'/ | }")
else
    RESULT="FAIL"
    a_output2+=(" - $TARGET_MODULE is missing or not enabled sufficiently. Found $L_COUNT entries (Expected min $EXPECTED_MIN_COUNT).")
    [ -n "$L_OUTPUT" ] && a_output+=(" - Partial findings: ${L_OUTPUT//$'\n'/ | }")
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