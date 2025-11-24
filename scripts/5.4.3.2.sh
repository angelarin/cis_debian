#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.3.2"
DESCRIPTION="Ensure default user shell timeout is configured (TMOUT <= 900, readonly, export)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
BRC="/etc/bashrc"
MAX_TMOUT=900
CONFIG_FILES=("$BRC" "/etc/profile" "/etc/profile.d/*.sh")

# --- 1. Cek Konfigurasi yang Benar (TMOUT <= 900, readonly, export) ---
output1=""
for f in "${CONFIG_FILES[@]}"; do
    if [ -f "$f" ]; then
        if grep -Pq '^\s*([^#]+\s+)?TMOUT=([1-9]|[1-9][0-9]|[1-8][0-9][0-9]|900)\b' "$f" && \
           grep -Pq '^\s*([^#]+;\s*)?readonly\s+TMOUT(\s+|\s*;|\s*$|=([1-9]|[1-9][0-9]|[1-8][0-9][0-9]|900))\b' "$f" && \
           grep -Pq '^\s*([^#]+;\s*)?export\s+TMOUT(\s+|\s*;|\s*$|=([1-9]|[1-9][0-9]|[1-8][0-9][0-9]|900))\b' "$f"; then
            output1="$f"
            break # Hanya perlu satu file yang dikonfigurasi dengan benar
        fi
    fi
done

# --- 2. Cek Konfigurasi yang Salah (TMOUT > 900 atau TMOUT=0) ---
output2=""
for f in "${CONFIG_FILES[@]}"; do
    if [ -f "$f" ]; then
        # Mencari TMOUT > 900 atau TMOUT=0
        L_VIOLATION=$(grep -Ps '^\s*([^#]+\s+)?TMOUT=(0+|9[0-9][1-9]|9[1-9][0-9]|[1-9]\d{3,})\b' "$f")
        if [ -n "$L_VIOLATION" ]; then
            output2="$output2\n$f: $L_VIOLATION"
        fi
    fi
done

# --- Assess Final Result ---
if [ -n "$output1" ] && [ -z "$output2" ]; then
    RESULT="PASS"
    a_output+=(" - TMOUT is configured correctly in: $output1 (Value <= $MAX_TMOUT, readonly, and exported).")
elif [ -n "$output2" ]; then
    RESULT="FAIL"
    output2=$(echo -e "$output2" | sed 's/\\n/ | /g')
    a_output2+=(" - TMOUT is incorrectly configured (set to 0 or > $MAX_TMOUT). Offending lines: $output2")
else
    RESULT="FAIL"
    a_output2+=(" - TMOUT is NOT configured with required settings (value <= $MAX_TMOUT, readonly, and exported).")
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