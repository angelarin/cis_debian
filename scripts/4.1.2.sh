#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 4.1.2"
DESCRIPTION="Ensure ufw service is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_ufw_service_chk()
{
    # 1. Verifikasi apakah service enabled (akan aktif saat boot)
    l_enabled=$(systemctl is-enabled ufw.service 2>/dev/null)
    if [ "$l_enabled" = "enabled" ]; then
        a_output+=(" - ufw.service is enabled")
    else
        a_output2+=(" - ufw.service is ${l_enabled:-not-found} (expected: enabled)")
    fi

    # 2. Verifikasi apakah service active (sedang berjalan)
    l_active=$(systemctl is-active ufw.service 2>/dev/null)
    if [ "$l_active" = "active" ]; then
        a_output+=(" - ufw.service is active")
    else
        a_output2+=(" - ufw.service is ${l_active:-inactive} (expected: active)")
    fi

    # 3. Verifikasi status internal UFW (rule engine aktif)
    # Kita menggunakan grep untuk memastikan output "Status: active"
    if ufw status 2>/dev/null | grep -qi "Status: active"; then
        a_output+=(" - ufw status is active")
    else
        l_ufw_stat=$(ufw status 2>/dev/null | grep "Status:" || echo "Status: unknown")
        a_output2+=(" - ufw $l_ufw_stat (expected: Status: active)")
    fi
}

# Jalankan prosedur pengecekan
f_ufw_service_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: UFW service is not properly configured | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}