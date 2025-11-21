#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.3.3"
DESCRIPTION="Ensure iptables are flushed with nftables (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="MANUAL" NOTES=""

# --- FUNGSI AUDIT IPTABLES FLUSH ---
# 1. Cek iptables (IPv4)
L_IPV4_OUTPUT=$(iptables -L 2>/dev/null | grep -E '^(Chain|Policy)')

if [ -z "$L_IPV4_OUTPUT" ] || echo "$L_IPV4_OUTPUT" | grep -q 'policy ACCEPT'; then
    a_output+=(" - IPv4 iptables output appears empty or uses default ACCEPT policy. Output: ${L_IPV4_OUTPUT//[$'\n']/\n}")
else
    a_output2+=(" - IPv4 iptables contains non-default rules/policies. Review required. Output: ${L_IPV4_OUTPUT//[$'\n']/\n}")
fi

# 2. Cek ip6tables (IPv6)
L_IPV6_OUTPUT=$(ip6tables -L 2>/dev/null | grep -E '^(Chain|Policy)')

if [ -z "$L_IPV6_OUTPUT" ] || echo "$L_IPV6_OUTPUT" | grep -q 'policy ACCEPT'; then
    a_output+=(" - IPv6 ip6tables output appears empty or uses default ACCEPT policy. Output: ${L_IPV6_OUTPUT//[$'\n']/\n}")
else
    a_output2+=(" - IPv6 ip6tables contains non-default rules/policies. Review required. Output: ${L_IPV6_OUTPUT//[$'\n']/\n}")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="MANUAL: Output shows no immediate non-default iptables. ${a_output[*]}"
else
    NOTES+="REVIEW: Non-default iptables rules detected. ${a_output2[*]}"
    NOTES+=" | INFO: ${a_output[*]}"
    RESULT="REVIEW"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}