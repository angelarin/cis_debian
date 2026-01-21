#!/usr/bin/env bash

# --- ID dan Deskripsi ---
CHECK_ID="4.3.3"
DESCRIPTION="Ensure iptables are flushed with nftables"

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT IPTABLES FLUSH ---

# 1. Cek IPv4 (iptables)
# Kita ambil semua output, bukan hanya header, untuk memastikan tidak ada rules tersembunyi
L_IPV4_ALL=$(iptables -L 2>/dev/null)
# Cek apakah Policy ACCEPT semua (Chain INPUT (policy ACCEPT)...)
L_IPV4_POLICIES=$(echo "$L_IPV4_ALL" | grep "policy" | grep -v "ACCEPT")
# Cek apakah ada rules (baris yang tidak diawali Chain, target, atau kosong)
L_IPV4_RULES=$(echo "$L_IPV4_ALL" | grep -vE "^Chain|^target|^$|^prot")

if [ -z "$L_IPV4_POLICIES" ] && [ -z "$L_IPV4_RULES" ]; then
    a_output+=("IPv4 iptables is flushed (Empty rules, Policy ACCEPT).")
else
    a_output2+=("IPv4 iptables is NOT flushed (Contains rules or Policy DROP/REJECT).")
fi

# 2. Cek IPv6 (ip6tables)
L_IPV6_ALL=$(ip6tables -L 2>/dev/null)
L_IPV6_POLICIES=$(echo "$L_IPV6_ALL" | grep "policy" | grep -v "ACCEPT")
L_IPV6_RULES=$(echo "$L_IPV6_ALL" | grep -vE "^Chain|^target|^$|^prot")

if [ -z "$L_IPV6_POLICIES" ] && [ -z "$L_IPV6_RULES" ]; then
    a_output+=("IPv6 ip6tables is flushed (Empty rules, Policy ACCEPT).")
else
    a_output2+=("IPv6 ip6tables is NOT flushed.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    # PERBAIKAN DI SINI: Jika tidak ada error (output2 kosong), set ke PASS
    RESULT="PASS"
    NOTES+="PASS: All iptables/ip6tables are flushed correctly. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: iptables are not flushed. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}
