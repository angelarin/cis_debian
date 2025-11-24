#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.1.5"
DESCRIPTION="Ensure inactive password lock is configured (INACTIVE <= 45 days)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SHADOW_FILE="/etc/shadow"
MAX_INACTIVE=45

# 1. Cek default INACTIVE di useradd -D
L_USERADD_OUTPUT=$(useradd -D 2>/dev/null | grep INACTIVE)
L_DEFAULT_VALUE=$(echo "$L_USERADD_OUTPUT" | awk -F= '{print $2}')

if [ -z "$L_DEFAULT_VALUE" ]; then
    a_output2+=(" - useradd -D: Could not determine default INACTIVE setting.")
    RESULT="FAIL"
elif [ "$L_DEFAULT_VALUE" -le "$MAX_INACTIVE" ] && [ "$L_DEFAULT_VALUE" -ge 0 ]; then
    a_output+=(" - Default INACTIVE setting ($L_DEFAULT_VALUE) conforms to site policy (<= $MAX_INACTIVE).")
else
    a_output2+=(" - Default INACTIVE setting ($L_DEFAULT_VALUE) does NOT conform to site policy (should be 0 to $MAX_INACTIVE).")
    RESULT="FAIL"
fi

# 2. Cek semua pengguna di /etc/shadow (kolom 7: inactive days)
# Cari pengguna dengan password yang di-hash yang melanggar batas
L_SHADOW_VIOLATION=$(awk -F: '($2~/^\$.+\$/) {if($7 > 45 || $7 < 0)print "User: " $1 " INACTIVE: " $7}' "$SHADOW_FILE" 2>/dev/null)

if [ -n "$L_SHADOW_VIOLATION" ]; then
    RESULT="FAIL"
    a_output2+=(" - $SHADOW_FILE: Found users with non-compliant INACTIVE days (outside 0-$MAX_INACTIVE range). Violations: ${L_SHADOW_VIOLATION//$'\n'/ | }")
else
    a_output+=(" - $SHADOW_FILE: All users with passwords have compliant INACTIVE days (0-$MAX_INACTIVE).")
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