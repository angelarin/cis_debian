#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.1.4"
DESCRIPTION="Ensure strong password hashing algorithm is configured (SHA512 or yescrypt)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
LOGIN_DEFS="/etc/login.defs"
EXPECTED_HASHES=("SHA512" "yescrypt")

# --- FUNGSI AUDIT ENCRYPT METHOD ---
L_OUTPUT=$(grep -Pi -- '^\h*ENCRYPT_METHOD\h+(SHA512|yescrypt)\b' "$LOGIN_DEFS" 2>/dev/null | tail -n 1)
L_VALUE=$(echo "$L_OUTPUT" | awk '{print $2}' | xargs)

if [ -n "$L_OUTPUT" ]; then
    a_output+=(" - $LOGIN_DEFS: ENCRYPT_METHOD is set to $L_VALUE.")
else
    # Cek nilai saat ini jika tidak ada match pada regex spesifik
    L_CURRENT_VALUE=$(grep -Pi -- '^\h*ENCRYPT_METHOD\h+\H+\b' "$LOGIN_DEFS" 2>/dev/null | tail -n 1 | awk '{print $2}' | xargs)
    if [ -n "$L_CURRENT_VALUE" ]; then
        RESULT="FAIL"
        a_output2+=(" - $LOGIN_DEFS: ENCRYPT_METHOD is set to $L_CURRENT_VALUE (Expected: SHA512 or yescrypt).")
    else
        RESULT="FAIL"
        a_output2+=(" - $LOGIN_DEFS: ENCRYPT_METHOD setting is MISSING or commented out.")
    fi
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