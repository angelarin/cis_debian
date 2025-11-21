#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.1.1"
DESCRIPTION="Ensure a single firewall configuration utility is in use"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
active_firewall=() firewalls=("ufw" "nftables" "iptables")

# --- FUNGSI AUDIT FIREWALL TUNGGAL ---
for firewall in "${firewalls[@]}"; do
    case $firewall in
    nftables)
        cmd="nft" ;;
    *)
        cmd=$firewall ;;
    esac
    
    # Cek apakah perintah tersedia, layanan diaktifkan, DAN aktif
    if command -v $cmd &> /dev/null && systemctl is-enabled --quiet "$firewall" && systemctl is-active --quiet "$firewall"; then
        active_firewall+=("$firewall")
    fi
done

# --- Assess combined status ---
if [ ${#active_firewall[@]} -eq 1 ]; then
    RESULT="PASS"
    a_output+=(" - A single firewall utility is in use: ${active_firewall[0]}")
elif [ ${#active_firewall[@]} -eq 0 ]; then
    RESULT="FAIL"
    a_output2+=(" - No primary firewall utility (ufw, nftables, iptables) is enabled and active.")
else
    RESULT="FAIL"
    a_output2+=(" - Multiple firewall utilities are enabled/active: ${active_firewall[*]}")
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