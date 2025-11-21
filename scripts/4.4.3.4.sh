#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.4.3.4"
DESCRIPTION="Ensure ip6tables firewall rules exist for all open ports"
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
    a_output+=(" - IPv6 is DISABLED on the system. ip6tables open port check is NOT APPLICABLE (PASS).")
    RESULT="PASS"
else
    # --- FUNGSI AUDIT PORT TERBUKA IP6TABLES ---
    
    # 1. Dapatkan daftar port IPv6 yang sedang didengarkan (TCP/UDP, non-loopback)
    unset a_openports
    while read -r line; do
        # Asumsi kolom ke-5 adalah Local Address:Port
        address_port=$(echo "$line" | awk '{print $5}')
        # Skip loopback (::1)
        if [[ "$address_port" != *::1:* ]]; then
            port=$(echo "$address_port" | awk -F: '{print $NF}')
            [ -n "$port" ] && a_openports+=("$port")
        fi
    done < <(ss -6tuln 2>/dev/null | tail -n +2)
    a_openports=($(printf "%s\n" "${a_openports[@]}" | sort -u))

    # 2. Dapatkan daftar port yang diizinkan oleh ip6tables INPUT chain (dpt:PORT)
    unset a_ip6tables_allowed
    L_INPUT_RULES=$(ip6tables -L INPUT -v -n 2>/dev/null | grep -E 'ACCEPT|target')

    if [ -z "$L_INPUT_RULES" ]; then
        RESULT="FAIL"
        a_output2+=(" - ip6tables INPUT chain rules could not be retrieved or are empty.")
    else
        while read -r rule; do
            if [[ "$rule" =~ dpt:([0-9]+) ]]; then
                a_ip6tables_allowed+=("${BASH_REMATCH[1]}")
            fi
        done < <(echo "$L_INPUT_RULES")
        a_ip6tables_allowed=($(printf "%s\n" "${a_ip6tables_allowed[@]}" | sort -u))
    fi

    # 3. Hitung perbedaan: Port yang terbuka TAPI TIDAK ADA di aturan ip6tables
    L_DIFF=$(
        comm -23 \
            <(printf '%s\n' "${a_openports[@]}" | sort -u) \
            <(printf '%s\n' "${a_ip6tables_allowed[@]}" | sort -u)
    )

    if [ -n "$L_DIFF" ]; then
        RESULT="FAIL"
        a_diff_list=$(echo "$L_DIFF" | tr '\n' ' ')
        a_output2+=(" - The following IPv6 port(s) are OPEN but don't have a matching ALLOW rule in ip6tables INPUT chain: $a_diff_list")
        a_output+=(" - Open IPv6 Ports detected: ${a_openports[*]:-None}")
        a_output+=(" - ip6tables Allowed Ports detected: ${a_ip6tables_allowed[*]:-None}")
    else
        a_output+=(" - All currently open IPv6 ports on non-loopback interfaces have a corresponding ALLOW rule in ip6tables.")
        a_output+=(" - Open IPv6 Ports detected: ${a_openports[*]:-None}")
        a_output+=(" - ip6tables Allowed Ports detected: ${a_ip6tables_allowed[*]:-None}")
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