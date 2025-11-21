#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.2.7"
DESCRIPTION="Ensure ufw default deny firewall policy"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
UFW_OUTPUT=$(ufw status verbose 2>/dev/null | grep 'Default:')
EXPECTED_POLICIES=("deny" "reject" "disabled")

# --- FUNGSI AUDIT DEFAULT POLICY ---
if [ -z "$UFW_OUTPUT" ]; then
    RESULT="FAIL"
    a_output2+=(" - Could not retrieve UFW default policy. UFW may be inactive or command failed.")
else
    a_output+=(" - Detected UFW default policies: $UFW_OUTPUT")
    
    # Ekstrak status untuk incoming, outgoing, dan routed
    INCOMING=$(echo "$UFW_OUTPUT" | grep -oP '\(incoming\),\s*\K\w+')
    OUTGOING=$(echo "$UFW_OUTPUT" | grep -oP '\(outgoing\),\s*\K\w+')
    ROUTED=$(echo "$UFW_OUTPUT" | grep -oP '\(routed\)\s*\K\w+')

    # Fungsi bantu untuk cek kebijakan
    check_policy() {
        local direction=$1
        local policy=$2
        local is_safe=0
        for expected in "${EXPECTED_POLICIES[@]}"; do
            if [ "$policy" = "$expected" ]; then
                is_safe=1
                break
            fi
        done
        
        if [ "$is_safe" -eq 0 ]; then
            a_output2+=(" - Default policy for $direction is set to '$policy' (Expected: deny, reject, or disabled).")
            RESULT="FAIL"
        fi
    }

    check_policy "incoming" "$INCOMING"
    check_policy "outgoing" "$OUTGOING"
    check_policy "routed" "$ROUTED"
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