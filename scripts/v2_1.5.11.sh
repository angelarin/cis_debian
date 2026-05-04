#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 1.5.11"
DESCRIPTION="Ensure core file size is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_limits_chk()
{
    # Menentukan file-file yang akan diperiksa
    l_files=("/etc/security/limits.conf")
    if [ -d "/etc/security/limits.d" ]; then
        # Mengumpulkan semua file .conf di limits.d
        while IFS= read -r -d $'\0' l_file; do
            l_files+=("$l_file")
        done < <(find /etc/security/limits.d -type f -name "*.conf" -print0 2>/dev/null)
    fi

    l_found="n"
    # Memeriksa setiap file
    for l_f in "${l_files[@]}"; do
        if [ -f "$l_f" ]; then
            # Mencari baris yang mengatur hard core limit untuk '*'
            while IFS= read -r l_line; do
                if [ -n "$l_line" ]; then
                    l_found="y"
                    # Mengambil nilai limit (kolom ke-4)
                    l_limit_val=$(echo "$l_line" | awk '{print $4}')
                    
                    if [ "$l_limit_val" = "0" ]; then
                        a_output+=(" - Hard core limit is 0 in \"$l_f\"")
                    else
                        a_output2+=(" - Insecure limit \"$l_limit_val\" found in \"$l_f\" (expected 0)")
                    fi
                fi
            done < <(grep -Psi -- '^\h*\*\h+hard\h+core\b' "$l_f")
        fi
    done

    # Jika tidak ada konfigurasi ditemukan sama sekali
    if [ "$l_found" = "n" ]; then
        a_output2+=(" - No hard core limit configured for '*' in /etc/security/limits.conf or limits.d/")
    fi
}

# Jalankan pengecekan
f_limits_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Core file size is not restricted to 0 | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}