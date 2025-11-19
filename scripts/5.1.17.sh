#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.17"
DESCRIPTION="Ensure sshd MaxSessions is configured (10 or less)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SETTING="MaxSessions"
MAX_VAL=10

# --- FUNGSI AUDIT MAX SESSIONS ---
L_OUTPUT=$(sshd -T 2>/dev/null | grep -i "$SETTING")
L_VALUE=$(echo "$L_OUTPUT" | awk '{print $2}' | xargs)

# Cek 1: Pemeriksaan nilai yang diterapkan (sshd -T)
if [ -z "$L_VALUE" ]; then
    # Default MaxSessions adalah 10, tetapi jika tidak ada output, kita anggap sebagai tinjauan.
    a_output+=(" - $SETTING is NOT explicitly set; relying on default (typically 10).")
    L_VALUE=$MAX_VAL # Assume default for evaluation
elif ! [[ "$L_VALUE" =~ ^[0-9]+$ ]]; then
    RESULT="FAIL"
    a_output2+=(" - $SETTING value is non-numeric (Value: $L_VALUE).")
elif [ "$L_VALUE" -le "$MAX_VAL" ]; then
    a_output+=(" - $SETTING is correctly set to $MAX_VAL or less (Value: $L_VALUE).")
    a_output+=(" - Detected setting: $L_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - $SETTING is set to $L_VALUE (Greater than maximum allowed value of $MAX_VAL).")
    a_output+=(" - Detected setting: $L_OUTPUT")
fi

# Cek 2: Pemeriksaan nilai yang salah pada file konfigurasi (RegEx: mencari > 10)
L_CONFIG_VIOLATION=$(grep -Psi -- '^\h*MaxSessions\h+\"?(1[1-9]|[2-9][0-9]|[1-9][0-9][0-9]+)\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

if [ -n "$L_CONFIG_VIOLATION" ]; then
    RESULT="FAIL"
    a_output2+=(" - Found configuration file violation where $SETTING > $MAX_VAL. Offending lines: $L_CONFIG_VIOLATION")
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