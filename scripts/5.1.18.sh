#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.18"
DESCRIPTION="Ensure sshd MaxStartups is configured (10:30:60 or more restrictive)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SETTING="MaxStartups"
MAX_START=10
MAX_RATE=30
MAX_FULL=60

# --- FUNGSI AUDIT MAX STARTUPS ---
L_OUTPUT=$(sshd -T 2>/dev/null | grep -i "$SETTING")
L_VALUE=$(echo "$L_OUTPUT" | awk '{print $2}' | xargs)

if [ -z "$L_VALUE" ]; then
    # Default MaxStartups adalah 10:30:60, tapi audit membutuhkan cek eksplisit
    a_output+=(" - $SETTING is NOT explicitly set; relying on default (typically 10:30:60).")
else
    a_output+=(" - Detected setting: $L_OUTPUT")
    
    # Pisahkan nilai start:rate:full
    IFS=':' read -r CURRENT_START CURRENT_RATE CURRENT_FULL <<< "$L_VALUE"

    # 1. Cek nilai START
    if [ -n "$CURRENT_START" ] && [ "$CURRENT_START" -gt "$MAX_START" ]; then
        RESULT="FAIL"
        a_output2+=(" - MaxStartups START value ($CURRENT_START) is greater than $MAX_START.")
    fi
    
    # 2. Cek nilai RATE
    if [ -n "$CURRENT_RATE" ] && [ "$CURRENT_RATE" -gt "$MAX_RATE" ]; then
        RESULT="FAIL"
        a_output2+=(" - MaxStartups RATE value ($CURRENT_RATE) is greater than $MAX_RATE.")
    fi
    
    # 3. Cek nilai FULL
    if [ -n "$CURRENT_FULL" ] && [ "$CURRENT_FULL" -gt "$MAX_FULL" ]; then
        RESULT="FAIL"
        a_output2+=(" - MaxStartups FULL value ($CURRENT_FULL) is greater than $MAX_FULL.")
    fi
fi

# Cek apakah ada output dari perintah audit yang mencurigakan (di mana setidaknya satu nilai > batas)
L_VIOLATION_CHECK=$(sshd -T 2>/dev/null | awk '$1 ~ /^\s*maxstartups/{split($2, a, ":");{if(a[1] > 10 || a[2] > 30 || a[3] > 60) print $0}}')

if [ -n "$L_VIOLATION_CHECK" ]; then
    RESULT="FAIL"
    a_output2+=(" - MaxStartups violation detected via audit command. Offending output: $L_VIOLATION_CHECK")
fi


# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}