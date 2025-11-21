#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.4.3.1"
DESCRIPTION="Ensure ip6tables default deny firewall policy"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
CHAINS=("INPUT" "FORWARD" "OUTPUT")
VALID_POLICIES=("DROP" "REJECT")

# --- FUNGSI CEK STATUS IPV6 (Digunakan untuk menentukan kelayakan audit) ---
l_ipv6_enabled="is"
! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable 2>/dev/null && l_ipv6_enabled="is not"
if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
   sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
l_ipv6_enabled="is not"
fi

if [ "$l_ipv6_enabled" = "is not" ]; then
    a_output+=(" - IPv6 is DISABLED on the system. ip6tables policy check is NOT APPLICABLE (PASS).")
    RESULT="PASS"
else
    # --- FUNGSI AUDIT DEFAULT POLICY IP6TABLES ---
    L_OUTPUT=$(ip6tables -L 2>/dev/null | grep 'Chain')

    if [ -z "$L_OUTPUT" ]; then
        RESULT="FAIL"
        a_output2+=(" - Could not retrieve ip6tables rules. ip6tables may not be configured.")
    else
        for chain in "${CHAINS[@]}"; do
            POLICY=$(echo "$L_OUTPUT" | grep "Chain $chain" | grep -oP '\(policy \K[^)]+')
            
            IS_SAFE=0
            for safe_policy in "${VALID_POLICIES[@]}"; do
                if [ "$POLICY" = "$safe_policy" ]; then
                    IS_SAFE=1
                    break
                fi
            done
            
            if [ "$IS_SAFE" -eq 1 ]; then
                a_output+=(" - Chain $chain policy is correctly set to $POLICY.")
            else
                RESULT="FAIL"
                a_output2+=(" - Chain $chain policy is set to $POLICY (Expected: DROP or REJECT).")
            fi
        done
        a_output+=(" - Full policies detected: ${L_OUTPUT//$'\n'/ | }")
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