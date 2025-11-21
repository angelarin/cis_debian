#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.4.2.4"
DESCRIPTION="Ensure iptables firewall rules exist for all open ports"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# 1. Dapatkan daftar port yang sedang didengarkan (IPv4, TCP/UDP, non-loopback)
unset a_openports
while read -r line; do
    # Asumsi kolom ke-5 adalah Local Address:Port
    address_port=$(echo "$line" | awk '{print $5}')
    # Skip loopback
    if [[ "$address_port" != *127.0.0.1:* ]]; then
        # Ekstrak port
        port=$(echo "$address_port" | awk -F: '{print $NF}')
        [ -n "$port" ] && a_openports+=("$port")
    fi
done < <(ss -4tuln 2>/dev/null | tail -n +2)
a_openports=($(printf "%s\n" "${a_openports[@]}" | sort -u))

# 2. Dapatkan daftar port yang diizinkan oleh iptables INPUT chain (dpt:PORT)
unset a_iptables_allowed
L_INPUT_RULES=$(iptables -L INPUT -v -n 2>/dev/null | grep -E 'ACCEPT|target')

if [ -z "$L_INPUT_RULES" ]; then
    RESULT="FAIL"
    a_output2+=(" - iptables INPUT chain rules could not be retrieved or are empty.")
else
    # Cari aturan ACCEPT/REJECT/RETURN yang mengandung dpt:PORT
    while read -r rule; do
        if [[ "$rule" =~ dpt:([0-9]+) ]]; then
            a_iptables_allowed+=("${BASH_REMATCH[1]}")
        fi
    done < <(echo "$L_INPUT_RULES")
    a_iptables_allowed=($(printf "%s\n" "${a_iptables_allowed[@]}" | sort -u))
fi

# 3. Hitung perbedaan: Port yang terbuka TAPI TIDAK ADA di aturan iptables
L_DIFF=$(
    comm -23 \
        <(printf '%s\n' "${a_openports[@]}" | sort -u) \
        <(printf '%s\n' "${a_iptables_allowed[@]}" | sort -u)
)

if [ -n "$L_DIFF" ]; then
    RESULT="FAIL"
    a_diff_list=$(echo "$L_DIFF" | tr '\n' ' ')
    a_output2+=(" - The following port(s) are OPEN but don't have a matching ALLOW rule in iptables INPUT chain: $a_diff_list")
    a_output+=(" - Open Ports detected: ${a_openports[*]:-None}")
    a_output+=(" - iptables Allowed Ports detected: ${a_iptables_allowed[*]:-None}")
else
    a_output+=(" - All currently open ports on non-loopback interfaces have a corresponding ALLOW rule in iptables.")
    a_output+=(" - Open Ports detected: ${a_openports[*]:-None}")
    a_output+=(" - iptables Allowed Ports detected: ${a_iptables_allowed[*]:-None}")
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