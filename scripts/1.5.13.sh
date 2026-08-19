#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 1.5.13"
DESCRIPTION="Ensure systemd-coredump Storage is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
l_conf_file="systemd/coredump.conf"
l_block="Coredump"
l_option="Storage"
RESULT="" NOTES=""

f_coredump_storage_chk()
{
    # 1. Periksa apakah systemd-coredump terpasang
    # Jika tidak terpasang, ini dianggap PASS (Passing State)
    if ! dpkg-query -s systemd-coredump &>/dev/null; then
        a_output+=(" - systemd-coredump package is not installed")
        return 0
    fi

    # 2. Mencari file konfigurasi menggunakan systemd-analyze
    l_analyze_cmd="$(readlink -e /bin/systemd-analyze || readlink -e /usr/bin/systemd-analyze)"
    
    if [ -n "$l_analyze_cmd" ]; then
        l_found="n"
        # Membaca konfigurasi dengan prioritas (tac digunakan untuk mendapatkan file override terakhir/terpenting)
        while IFS= read -r l_file; do
            l_file="${l_file//# /}"
            if [ -f "$l_file" ]; then
                # Mencari opsi Storage di dalam blok [Coredump]
                l_opt="$(awk '/\['"$l_block"'\]/{a=1;next}/\[/{a=0}a' "$l_file" 2>/dev/null | grep -Poi '^\h*'"$l_option"'\h*=\h*\H+\b' | tail -n 1)"
                l_option_value="$(cut -d= -f2 <<< "$l_opt" | xargs)"

                if [ -n "$l_option_value" ]; then
                    l_found="y"
                    if [ "$l_option_value" = "none" ]; then
                        a_output+=(" - \"$l_option\" is set to \"none\" in \"$l_file\"")
                    else
                        a_output2+=(" - \"$l_option\" is set to \"$l_option_value\" in \"$l_file\" (expected none)")
                    fi
                    # Berhenti setelah menemukan nilai konfigurasi efektif pertama (prioritas tertinggi)
                    break
                fi
            fi
        done < <("$l_analyze_cmd" cat-config "$l_conf_file" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

        # 3. Jika tidak ditemukan di override, periksa nilai default di file utama
        if [ "$l_found" = "n" ]; then
            l_main_file="$(readlink -e /etc/"$l_conf_file" || readlink -e /usr/lib/"$l_conf_file")"
            if [ -f "$l_main_file" ]; then
                l_opt="$(awk '/\['"$l_block"'\]/{a=1;next}/\[/{a=0}a' "$l_main_file" 2>/dev/null | grep -Poim 1 '^(\h*#)?\h*'"$l_option"'\h*=\h*\H+\b')"
                l_option_value="$(cut -d= -f2 <<< "${l_opt//# /}" | xargs)"
                
                if [ "$l_option_value" = "none" ]; then
                    a_output+=(" - Default value \"$l_option=none\" is being used (found in $l_main_file)")
                else
                    a_output2+=(" - No configuration found and default is not \"none\"")
                fi
            fi
        fi
    else
        a_output2+=(" - systemd-analyze command not found, cannot audit systemd-coredump")
    fi
}

# Jalankan pengecekan
f_coredump_storage_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: systemd-coredump storage configuration issues found | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}