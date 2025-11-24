#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.2.1"
DESCRIPTION="Ensure pam_unix module is enabled"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="FAIL" NOTES=""
TARGET_MODULE="pam_unix\.so"
EXPECTED_COUNT=5 # Ada 5 file yang dicek

# --- FUNGSI AUDIT PAM UNIX ---
# FIX: Memasukkan daftar file langsung agar Brace Expansion bekerja.
L_OUTPUT=$(grep -PH -- "\b$TARGET_MODULE\b" /etc/pam.d/common-{account,auth,password,session,session-noninteractive})
L_COUNT=$(echo "$L_OUTPUT" | grep -c "\b$TARGET_MODULE\b")

if [ "$L_COUNT" -ge "$EXPECTED_COUNT" ]; then
    RESULT="PASS"
    a_output+=(" - $TARGET_MODULE is enabled in at least $EXPECTED_COUNT common-* files.")
    a_output+=(" - Detected lines: ${L_OUTPUT//$'\n'/ | }")
else
    RESULT="FAIL"
    a_output2+=(" - $TARGET_MODULE is missing or not enabled in all required files. Found $L_COUNT entries (Expected $EXPECTED_COUNT).")
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