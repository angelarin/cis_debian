#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.4.2.2"
DESCRIPTION="Ensure iptables loopback traffic is configured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# 1. Cek INPUT Chain untuk ACCEPT loopback interface dan DROP loopback network
L_INPUT_OUTPUT=$(iptables -L INPUT -v -n 2>/dev/null)

if [ -z "$L_INPUT_OUTPUT" ]; then
    RESULT="FAIL"
    a_output2+=(" - Could not retrieve iptables INPUT chain rules.")
else
    # Cek ACCEPT all -- lo * 0.0.0.0/0 0.0.0.0/0
    if echo "$L_INPUT_OUTPUT" | grep -q 'ACCEPT\s+all\s+--\s+lo\s+\*\s+0\.0\.0\.0/0\s+0\.0\.0\.0/0'; then
        a_output+=(" - INPUT: Rule to ACCEPT traffic on loopback interface (lo) found.")
    else
        RESULT="FAIL"
        a_output2+=(" - INPUT: Rule to ACCEPT traffic on loopback interface (lo) is MISSING or incorrect.")
    fi

    # Cek DROP all -- * * 127.0.0.0/8 0.0.0.0/0
    if echo "$L_INPUT_OUTPUT" | grep -q 'DROP\s+all\s+--\s+\*\s+\*\s+127\.0\.0\.0/8\s+0\.0\.0\.0/0'; then
        a_output+=(" - INPUT: Rule to DROP traffic from loopback network (127.0.0.0/8) found.")
    else
        RESULT="FAIL"
        a_output2+=(" - INPUT: Rule to DROP traffic from loopback network (127.0.0.0/8) is MISSING or incorrect.")
    fi
fi

# 2. Cek OUTPUT Chain untuk ACCEPT loopback interface
L_OUTPUT_OUTPUT=$(iptables -L OUTPUT -v -n 2>/dev/null)

if [ -z "$L_OUTPUT_OUTPUT" ]; then
    # Jika INPUT berhasil tapi OUTPUT gagal, hanya berikan warning
    [ "$RESULT" = "PASS" ] && RESULT="REVIEW"
    a_output2+=(" - Could not retrieve iptables OUTPUT chain rules.")
else
    # Cek ACCEPT all -- * lo 0.0.0.0/0 0.0.0.0/0
    if echo "$L_OUTPUT_OUTPUT" | grep -q 'ACCEPT\s+all\s+--\s+\*\s+lo\s+0\.0\.0\.0/0\s+0\.0\.0\.0/0'; then
        a_output+=(" - OUTPUT: Rule to ACCEPT traffic on loopback interface (lo) found.")
    else
        RESULT="FAIL"
        a_output2+=(" - OUTPUT: Rule to ACCEPT traffic on loopback interface (lo) is MISSING or incorrect.")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

if [ "$RESULT" = "REVIEW" ]; then
    NOTES=$(echo "$NOTES" | sed 's/PASS/REVIEW/g')
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}