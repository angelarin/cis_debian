#!/usr/bin/env bash

CHECK_ID="4.3.6"
DESCRIPTION="Ensure nftables loopback traffic is configured"

{
a_output=() a_output2=() RESULT="" NOTES=""

# Ambil Ruleset saat ini
L_RULESET=$(nft list ruleset 2>/dev/null)

# 1. Cek Loopback Interface Accept (iif "lo" accept)
if echo "$L_RULESET" | awk '/hook input/,/}/' | grep -q 'iif "lo" accept'; then
    a_output+=("Loopback interface is configured to ACCEPT traffic.")
else
    a_output2+=("Loopback interface ACCEPT rule is MISSING.")
fi

# 2. Cek IPv4 Loopback Spoofing Drop (127.0.0.0/8 drop)
if echo "$L_RULESET" | awk '/hook input/,/}/' | grep -q 'ip saddr 127.0.0.0/8.*drop'; then
    a_output+=("IPv4 loopback spoofing is configured to DROP.")
else
    a_output2+=("IPv4 loopback spoofing DROP rule is MISSING.")
fi

# 3. Cek IPv6 Loopback Spoofing Drop (::1 drop) - Jika IPv6 aktif
if [ -f /proc/net/if_inet6 ]; then
    if echo "$L_RULESET" | awk '/hook input/,/}/' | grep -q 'ip6 saddr ::1.*drop'; then
        a_output+=("IPv6 loopback spoofing is configured to DROP.")
    else
        a_output2+=("IPv6 loopback spoofing DROP rule is MISSING.")
    fi
fi

# --- LOGIKA OUTPUT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s): ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}
