#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.4.3.2"
DESCRIPTION="Ensure ip6tables loopback traffic is configured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# --- FUNGSI CEK STATUS IPV6 ---
l_ipv6_enabled="is"
! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable 2>/dev/null && l_ipv6_enabled="is not"
if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
   sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
l_ipv6_enabled="is not"
fi

if [ "$l_ipv6_enabled" = "is not" ]; then
    a_output+=(" - IPv6 is DISABLED on the system. ip6tables loopback check is NOT APPLICABLE (PASS).")
    RESULT="PASS"
else
    # --- FUNGSI AUDIT LOOPBACK IP6TABLES ---
    L_INPUT_OUTPUT=$(ip6tables -L INPUT -v -n 2>/dev/null)
    L_OUTPUT_OUTPUT=$(ip6tables -L OUTPUT -v -n 2>/dev/null)

    if [ -z "$L_INPUT_OUTPUT" ] || [ -z "$L_OUTPUT_OUTPUT" ]; then
        RESULT="FAIL"
        a_output2+=(" - Could not retrieve ip6tables rules.")
    else
        # 1. Cek INPUT: ACCEPT all lo * ::/0 ::/0
        if echo "$L_INPUT_OUTPUT" | grep -q 'ACCEPT\s+all\s+--\s+lo\s+\*\s+::/0\s+::/0'; then
            a_output+=(" - INPUT: Rule to ACCEPT traffic on loopback interface (lo) found.")
        else
            RESULT="FAIL"
            a_output2+=(" - INPUT: Loopback interface ACCEPT rule is MISSING or incorrect.")
        fi

        # 2. Cek INPUT: DROP all * * ::1 ::/0
        if echo "$L_INPUT_OUTPUT" | grep -q 'DROP\s+all\s+--\s+\*\s+\*\s+::1\s+::/0'; then
            a_output+=(" - INPUT: Rule to DROP traffic from IPv6 loopback network (::1) found.")
        else
            RESULT="FAIL"
            a_output2+=(" - INPUT: IPv6 loopback network DROP rule is MISSING or incorrect.")
        fi

        # 3. Cek OUTPUT: ACCEPT all * lo ::/0 ::/0
        if echo "$L_OUTPUT_OUTPUT" | grep -q 'ACCEPT\s+all\s+--\s+\*\s+lo\s+::/0\s+::/0'; then
            a_output+=(" - OUTPUT: Rule to ACCEPT traffic on loopback interface (lo) found.")
        else
            RESULT="FAIL"
            a_output2+=(" - OUTPUT: Loopback interface ACCEPT rule is MISSING or incorrect.")
        fi
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