#!/usr/bin/env bash

CHECK_ID="5.3.3.4.1"
DESCRIPTION="Ensure pam_unix does not include nullok"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILES="/etc/pam.d/common-{password,auth,account,session,session-noninteractive}"
UNEXPECTED_ARGUMENT="nullok"

# --- FUNGSI AUDIT NULLOK (Menggunakan Exit Code) ---
L_OUTPUT=$(grep -PHs -- '^\h*[^#\n\r]+\h+pam_unix\.so\h+([^#\n\r]+\h+)?nullok\b' $TARGET_FILES 2>/dev/null)
GREP_EXIT_CODE=$? 

if [ "$GREP_EXIT_CODE" -eq 0 ]; then
    # Jika kode keluar 0, berarti 'nullok' ditemukan.
    RESULT="FAIL"
    # Bersihkan output grep untuk log
    CLEAN_OUTPUT=$(echo "$L_OUTPUT" | tr '\n' ' | ' | sed 's/ | $//')
    a_output2+=("- Detected '$UNEXPECTED_ARGUMENT' argument on pam_unix.so line(s). Offending lines: $CLEAN_OUTPUT")
else
    # Jika kode keluar bukan 0, berarti 'nullok' tidak ditemukan.
    a_output+=("- No instances of '$UNEXPECTED_ARGUMENT' found on pam_unix.so lines.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "PASS" ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}