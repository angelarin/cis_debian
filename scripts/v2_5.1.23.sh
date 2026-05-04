#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 5.1.13"
DESCRIPTION="Ensure sshd post-quantum cryptography key exchange algorithms are configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_sshd_pqc_chk()
{
    # 1. Cari path sshd
    l_sshd_path="$(readlink -e /usr/sbin/sshd || readlink -e /sbin/sshd)"
    
    if [ ! -f "$l_sshd_path" ]; then
        a_output2+=(" - sshd binary tidak ditemukan (SSH mungkin tidak terinstal)")
        return
    fi

    # 2. Tentukan versi OpenSSH
    l_ssh_v_full=$("$l_sshd_path" -V 2>&1 | grep -Psio 'openssh_\d+\.\d+')
    l_ssh_version=$(echo "$l_ssh_v_full" | awk -F'_' '{print $2}')
    a_output+=(" - Versi OpenSSH terdeteksi: $l_ssh_version")

    # 3. Ambil daftar kexalgorithms yang aktif
    l_kex_active=$("$l_sshd_path" -T | awk '$1=="kexalgorithms" {print $2}')

    # 4. Verifikasi sntrup761x25519-sha512 (Wajib untuk semua versi yang mendukung PQC)
    if echo "$l_kex_active" | grep -q "sntrup761x25519-sha512"; then
        a_output+=(" - Algoritma 'sntrup761x25519-sha512' tersedia")
    else
        a_output2+=(" - Algoritma 'sntrup761x25519-sha512' tidak ditemukan dalam konfigurasi")
    fi

    # 5. Verifikasi mlkem768x25519-sha256 jika versi >= 9.9
    # Menggunakan awk untuk perbandingan versi numerik
    if [ -n "$l_ssh_version" ] && [ "$(echo "$l_ssh_version >= 9.9" | bc -l 2>/dev/null || awk -v n1="$l_ssh_version" -v n2="9.9" 'BEGIN {print (n1 >= n2)}')" -eq 1 ]; then
        if echo "$l_kex_active" | grep -q "mlkem768x25519-sha256"; then
            a_output+=(" - Algoritma 'mlkem768x25519-sha256' (v9.9+) tersedia")
        else
            a_output2+=(" - OpenSSH v9.9+ terdeteksi, tetapi 'mlkem768x25519-sha256' tidak ditemukan")
        fi
    fi
}

# Jalankan prosedur pengecekan
f_sshd_pqc_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Post-Quantum Cryptography KEX is missing or misconfigured | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}