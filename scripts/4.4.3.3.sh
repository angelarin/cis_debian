#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.4.3.3"
DESCRIPTION="Ensure ip6tables outbound and established connections are configured (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="MANUAL" NOTES=""

# --- FUNGSI CEK STATUS IPV6 ---
l_ipv6_enabled="is"
! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable 2>/dev/null && l_ipv6_enabled="is not"
if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
   sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
l_ipv6_enabled="is not"
fi

if [ "$l_ipv6_enabled" = "is not" ]; then
    a_output+=(" - IPv6 is DISABLED on the system. ip6tables check is NOT APPLICABLE (MANUAL PASS).")
    RESULT="PASS" # Ubah ke PASS karena audit tidak berlaku
else
    # --- FUNGSI AUDIT MANUAL ---
    L_OUTPUT=$(ip6tables -L -v -n 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$L_OUTPUT" ]; then
        a_output+=(" - ip6tables is configured. Review the full ruleset below to ensure all new outbound and established connections match site policy.")
        a_output+=(" - Full ip6tables Ruleset:\n$L_OUTPUT\n")
        
        # Deteksi aturan established/related
        L_ESTABLISHED=$(echo "$L_OUTPUT" | grep 'state ESTABLISHED,RELATED')
        [ -n "$L_ESTABLISHED" ] && a_output+=(" - Established/Related rules detected: ${L_ESTABLISHED//$'\n'/ | }")
    else
        a_output2+=(" - Could not retrieve ip6tables ruleset.")
        RESULT="FAIL"
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "PASS" ]; then
    NOTES+="PASS: ${a_output[*]}"
elif [ "$RESULT" == "MANUAL" ]; then
    NOTES+="MANUAL: Review required. Check full ip6tables ruleset against site policy. ${a_output[*]}"
elif [ "$RESULT" == "FAIL" ]; then
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}