#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.2.4"
DESCRIPTION="Ensure ufw loopback traffic is configured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
UFW_BEFORE_RULES="/etc/ufw/before.rules"

# 1. Cek Loopback di before.rules (Harus ada: ACCEPT)
L_RULES_LOOPBACK=$(grep -P -- 'lo|127.0.0.0' "$UFW_BEFORE_RULES" 2>/dev/null)
if echo "$L_RULES_LOOPBACK" | grep -q '\-i lo \-j ACCEPT' && echo "$L_RULES_LOOPBACK" | grep -q '\-o lo \-j ACCEPT'; then
    a_output+=(" - Loopback traffic ALLOWED in $UFW_BEFORE_RULES (i lo ACCEPT and o lo ACCEPT).")
else
    RESULT="FAIL"
    a_output2+=(" - Loopback traffic is NOT explicitly ALLOWED in $UFW_BEFORE_RULES.")
fi

# 2. Cek Deny Loopback Network di ufw status (Harus ada: DENY IN 127.0.0.0/8 dan DENY IN ::1)
L_STATUS_DENY=$(ufw status verbose 2>/dev/null | grep -E '127\.0\.0\.0/8|::1')
if echo "$L_STATUS_DENY" | grep -q 'DENY IN 127\.0\.0\.0/8' && echo "$L_STATUS_DENY" | grep -q 'DENY IN ::1'; then
    a_output+=(" - Deny rules for incoming loopback network traffic (127.0.0.0/8 and ::1) are correctly set. Detected: ${L_STATUS_DENY//$'\n'/ | }")
else
    RESULT="FAIL"
    a_output2+=(" - Deny rules for incoming loopback network traffic (127.0.0.0/8 and/or ::1) are missing or incorrect. Detected: ${L_STATUS_DENY//$'\n'/ | }")
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