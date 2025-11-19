#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="3.1.1"
DESCRIPTION="Ensure IPv6 status is identified (Manual Review Required)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
l_output=""

# --- FUNGSI AUDIT IPV6 STATUS ---
# 1. Cek /sys/module/ipv6/parameters/disable
if grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable; then
    # Jika nilainya 0, artinya IPv6 TIDAK dinonaktifkan di level kernel module
    l_output=" - IPv6 is NOT disabled at kernel module level."
fi

# 2. Cek sysctl net.ipv6.conf.all.disable_ipv6 dan net.ipv6.conf.default.disable_ipv6
if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
   sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
    # Kedua sysctl diatur ke 1, artinya IPv6 dinonaktifkan via sysctl
    l_output=" - IPv6 is disabled via sysctl (all and default interfaces set to 1)."
fi

# Tentukan status akhir
if [ -z "$l_output" ]; then
    # Jika l_output masih kosong setelah semua cek, berarti status default adalah ENABLED
    l_output=" - IPv6 is ENABLED and possibly active on interfaces."
    FINAL_STATUS="ENABLED"
else
    FINAL_STATUS="DISABLED/CHECK SYSCTL"
fi

a_output+=("Final IPv6 Status Check: $l_output")

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES+="INFO: Status detected: $FINAL_STATUS. ${a_output[*]}"
NOTES+=" | Action: REVIEW against local site policy to ensure the correct status (enabled/disabled) is achieved."
RESULT="REVIEW"

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}