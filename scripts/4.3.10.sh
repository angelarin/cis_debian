#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.3.10"
DESCRIPTION="Ensure nftables rules are permanent"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILE="/etc/nftables.conf"
REQUIRED_HOOKS=("input" "forward" "output")

# --- FUNGSI AUDIT PERSISTENSI ---

# Tentukan file yang di-include untuk ruleset
L_INCLUDE_FILES=$(grep -E '^\s*include' "$TARGET_FILE" 2>/dev/null | awk '$1 ~ /^\s*include/ { gsub("\"","",$2);print $2 }')

if [ -z "$L_INCLUDE_FILES" ] && ! [ -f "$TARGET_FILE" ]; then
    RESULT="FAIL"
    a_output2+=(" - $TARGET_FILE is missing or contains no 'include' directives to load rules.")
else
    # Gabungkan file utama dan file yang di-include
    ALL_CONFIG_FILES=("$TARGET_FILE" $L_INCLUDE_FILES)
    CONFIG_CONTENT=$(cat "${ALL_CONFIG_FILES[@]}" 2>/dev/null)
    
    if [ -z "$CONFIG_CONTENT" ]; then
        RESULT="FAIL"
        a_output2+=(" - Configuration files were found but are empty or unreadable.")
    else
        # Cek setiap base chain
        for hook in "${REQUIRED_HOOKS[@]}"; do
            if echo "$CONFIG_CONTENT" | grep -q "hook $hook"; then
                a_output+=(" - Base chain 'hook $hook' found in permanent configuration.")
            else
                RESULT="FAIL"
                a_output2+=(" - Base chain 'hook $hook' is MISSING from permanent configuration files.")
            fi
        done
        
        # NOTE: Pemeriksaan kualitas/konten base chain harus dilakukan secara manual (seperti contoh audit)
        a_output+=(" - Rule content review is required to ensure policies are applied correctly on boot.")
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