#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.3.1.2"
DESCRIPTION="Ensure AppArmor is enabled"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_audit_apparmor_enabled_chk()
{
    # 1. Periksa file konfigurasi grub untuk parameter penonaktifan
    if [ -f /boot/grub/grub.cfg ]; then
        l_grub_check=$(grep "^\s*linux" /boot/grub/grub.cfg | grep "apparmor=0")
        
        if [ -z "$l_grub_check" ]; then
            a_output+=(" - Parameter 'apparmor=0' tidak ditemukan di grub.cfg (AppArmor tidak dimatikan lewat bootloader)")
        else
            a_output2+=(" - Terdeteksi 'apparmor=0' di grub.cfg, AppArmor dinonaktifkan pada saat boot")
        fi
    else
        a_output2+=(" - File /boot/grub/grub.cfg tidak ditemukan. Pastikan sistem menggunakan GRUB.")
    fi

    # 2. Verifikasi tambahan: Periksa status AppArmor di kernel
    if [ -d /sys/module/apparmor ]; then
        l_enabled=$(cat /sys/module/apparmor/parameters/enabled 2>/dev/null)
        if [ "$l_enabled" = "Y" ]; then
            a_output+=(" - Modul kernel AppArmor terdeteksi aktif (enabled=Y)")
        else
            a_output2+=(" - Modul kernel AppArmor terdeteksi tidak aktif (enabled=$l_enabled)")
        fi
    else
        a_output2+=(" - Modul kernel AppArmor tidak terdeteksi")
    fi
}

# Jalankan prosedur pengecekan
f_audit_apparmor_enabled_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: AppArmor is disabled or not configured correctly | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV/Log
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}