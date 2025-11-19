#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.1.21"
DESCRIPTION="Ensure mail transfer agent is configured for local-only mode"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
a_port_list=("25" "465" "587")

# --- 1. Cek status port aktif non-loopback ---
for l_port_number in "${a_port_list[@]}"; do
    if ss -plntu | grep -P -- ':'"$l_port_number"'\b' | grep -Pvq -- '\h+(127\.0\.0\.1|\[?::1\]?):'"$l_port_number"'\b'; then
        RESULT="FAIL"
        a_output2+=(" - Port \"$l_port_number\" is listening on a non-loopback network interface")
    else
        a_output+=(" - Port \"$l_port_number\" is not listening on a non-loopback network interface")
    fi
done

# --- 2. Cek konfigurasi MTA (Postfix/Exim/Sendmail) ---
l_interfaces=""
if command -v postconf &> /dev/null; then
    l_interfaces="$(postconf -n inet_interfaces)"
    MTA_TYPE="Postfix"
elif command -v exim &> /dev/null; then
    l_interfaces="$(exim -bP local_interfaces)"
    MTA_TYPE="Exim"
elif command -v sendmail &> /dev/null; then
    # Menggunakan regex lookbehind yang lebih sederhana untuk kompatibilitas
    l_interfaces="$(grep -i "0 DaemonPortOptions=" /etc/mail/sendmail.cf 2>/dev/null | grep -oP 'Addr=)[^,+]+' | cut -d')' -f2)"
    MTA_TYPE="Sendmail"
fi

if [ -n "$l_interfaces" ]; then
    a_output+=(" - Detected MTA ($MTA_TYPE) interface setting: $l_interfaces")

    if grep -Pqi '\ball\b' <<< "$l_interfaces"; then
        RESULT="FAIL"
        a_output2+=(" - MTA is bound to all network interfaces ('all')")

    elif ! grep -Pqi '(inet_interfaces\h*=\h*)?(0\.0\.0\.0|::1|loopback-only)' <<< "$l_interfaces"; then
        # Jika bukan 'all' dan tidak mengandung loopback-only atau 0.0.0.0/::1
        RESULT="FAIL"
        a_output2+=(" - MTA is bound to a specific non-loopback network interface \"$l_interfaces\"")
    else
        a_output+=(" - MTA is configured not to bind to a non-loopback network interface.")
    fi
else
    a_output+=(" - No common MTA configuration (Postfix, Exim, Sendmail) detected or in use.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    # Jika ada kegagalan port atau konfigurasi
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}