#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.2.6"
DESCRIPTION="Ensure ufw firewall rules exist for all open ports"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# 1. Dapatkan daftar port UFW yang diizinkan (hanya nomor port)
unset a_ufwout
while read -r l_ufwport; do
    [ -n "$l_ufwport" ] && a_ufwout+=("$l_ufwport")
done < <(ufw status verbose | grep -Po '^\h*\d+\b' | sort -u)

# 2. Dapatkan daftar port yang sedang didengarkan (non-loopback)
unset a_openports
while read -r l_openport; do
    [ -n "$l_openport" ] && a_openports+=("$l_openport")
done < <(ss -tuln 2>/dev/null | awk '($5!~/%lo:/ && $5!~/127.0.0.1:/ && $5!~/\[?::1\]?:/) {split($5, a, ":"); print a[2]}' | sort -u)

# 3. Hitung perbedaan: Port yang terbuka TAPI TIDAK ADA di UFW
# Perintah ini menggabungkan kedua list, menyortir, dan menampilkan hanya item yang muncul sekali (yang tidak ada di kedua list).
# Kemudian hanya mempertahankan port yang ada di a_openports tetapi tidak di a_ufwout.
# Karena urutan uniknya tidak terjamin, kita gunakan logika set difference yang lebih aman:
# (A \ B) = (A + B) \ (A intersect B)
L_DIFF=$(
    comm -23 \
        <(printf '%s\n' "${a_openports[@]}" | sort -u) \
        <(printf '%s\n' "${a_ufwout[@]}" | sort -u)
)

if [ -n "$L_DIFF" ]; then
    RESULT="FAIL"
    a_diff_list=$(echo "$L_DIFF" | tr '\n' ' ')
    a_output2+=(" - The following port(s) are OPEN but don't have a matching ALLOW rule in UFW: $a_diff_list")
    a_output+=(" - Open Ports detected: ${a_openports[*]:-None}")
    a_output+=(" - UFW Allowed Ports detected: ${a_ufwout[*]:-None}")
else
    a_output+=(" - All currently open ports on non-loopback interfaces have a corresponding ALLOW rule in UFW.")
    a_output+=(" - Open Ports detected: ${a_openports[*]:-None}")
    a_output+=(" - UFW Allowed Ports detected: ${a_ufwout[*]:-None}")
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