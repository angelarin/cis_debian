#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.3.8"
DESCRIPTION="Ensure nftables default deny firewall policy"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
REQUIRED_HOOKS=("input" "forward" "output")

# --- FUNGSI AUDIT DEFAULT POLICY ---
L_RULESET=$(nft list ruleset 2>/dev/null)

if [ -z "$L_RULESET" ]; then
    RESULT="FAIL"
    a_output2+=(" - nftables ruleset is empty. Cannot check default policy.")
else
    for hook in "${REQUIRED_HOOKS[@]}"; do
        L_HOOK_LINE=$(echo "$L_RULESET" | grep "hook $hook")
        
        if echo "$L_HOOK_LINE" | grep -Pq 'policy\s+drop\b'; then
            a_output+=(" - Base chain 'hook $hook' policy is correctly set to DROP.")
        else
            RESULT="FAIL"
            a_output2+=(" - Base chain 'hook $hook' policy is NOT set to DROP. Detected: $L_HOOK_LINE")
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