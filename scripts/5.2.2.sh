#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.2.2"
DESCRIPTION="Ensure sudo commands use pty (use_pty is set)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
EXPECTED_SETTING='^\h*Defaults\h+([^#\n\r]+,\h*)?use_pty\b'
UNEXPECTED_SETTING='^\h*Defaults\h+([^#\n\r]+,\h*)?!use_pty\b'

# 1. Cek Defaults use_pty (Harus ada)
L_OUTPUT_USE_PTY=$(grep -rPi -- "$EXPECTED_SETTING" /etc/sudoers /etc/sudoers.d/* 2>/dev/null)

if [ -n "$L_OUTPUT_USE_PTY" ]; then
    a_output+=(" - Defaults use_pty is correctly set.")
    a_output+=(" - Detected lines: $L_OUTPUT_USE_PTY")
else
    RESULT="FAIL"
    a_output2+=(" - Defaults use_pty is NOT set.")
fi

# 2. Cek Defaults !use_pty (Tidak boleh ada)
L_OUTPUT_NOT_USE_PTY=$(grep -rPi -- "$UNEXPECTED_SETTING" /etc/sudoers /etc/sudoers.d/* 2>/dev/null)

if [ -n "$L_OUTPUT_NOT_USE_PTY" ]; then
    RESULT="FAIL"
    a_output2+=(" - Defaults !use_pty (Disabling pty) is set. Offending lines: $L_OUTPUT_NOT_USE_PTY")
else
    a_output+=(" - Defaults !use_pty is NOT set.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set/Info: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}