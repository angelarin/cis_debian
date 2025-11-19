#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.15"
DESCRIPTION="Ensure sshd MACs are configured (no weak MACs)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# Daftar weak MACs yang dicek (termasuk ETM variants yang dicontohkan)
WEAK_MACS_REGEX='macs\h+([^#\n\r]+,)?(hmac-md5|hmac-md5-96|hmac-ripemd160|hmac-sha1-96|umac-64@openssh\.com|hmac-md5-etm@openssh\.com|hmac-md5-96-etm@openssh\.com|hmac-ripemd160-etm@openssh\.com|hmac-sha1-96-etm@openssh\.com|umac-64-etm@openssh\.com|umac-128-etm@openssh\.com)\b'

# Cek apakah konfigurasi MACs mengandung weak MACs
L_OUTPUT=$(sshd -T 2>/dev/null | grep -Pi -- "$WEAK_MACS_REGEX")
L_ALL_MACS=$(sshd -T 2>/dev/null | grep -Pi -- '^macs\h+')

# 1. Cek keberadaan weak MACs
if [ -z "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=(" - No explicitly configured weak MACs detected.")
else
    RESULT="FAIL"
    a_output2+=(" - Detected WEAK/DEPRECATED MACs being explicitly configured: $L_OUTPUT")
    a_output2+=(" - WARNING: Review CVE-2023-48795, particularly if ETM MACs are present.")
fi

# 2. Cek apakah ada konfigurasi MACs sama sekali (jika PASS)
if [ -n "$L_ALL_MACS" ]; then
    a_output+=(" - MACs directive is explicitly set. Current setting: $L_ALL_MACS")
else
    a_output+=(" - MACs directive is NOT explicitly set; system relies on OpenSSH defaults.")
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