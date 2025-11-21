#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.3.5"
DESCRIPTION="Ensure nftables base chains exist"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
REQUIRED_HOOKS=("input" "forward" "output")

# --- FUNGSI AUDIT BASE CHAINS ---
L_RULESET=$(nft list ruleset 2>/dev/null)

if [ -z "$L_RULESET" ]; then
    RESULT="FAIL"
    a_output2+=(" - nftables ruleset is empty. No base chains can be checked.")
else
    for hook in "${REQUIRED_HOOKS[@]}"; do
        if echo "$L_RULESET" | grep -q "hook $hook"; then
            a_output+=(" - Base chain with 'hook $hook' found.")
        else
            RESULT="FAIL"
            a_output2+=(" - Base chain with 'hook $hook' is MISSING from the ruleset.")
        fi
    done
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