#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.3.2.1"
DESCRIPTION="Ensure systemd-timesyncd configured with authorized timeserver"
# -----------------------------------------------------

{
a_output=() a_output2=() a_output3=() a_out=() a_out2=()
a_parlist=("NTP=[^#\n\r]+" "FallbackNTP=[^#\n\r]+")
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_systemd_config_file="/etc/systemd/timesyncd.conf"
RESULT="" NOTES=""

# --- DAFTAR SERVER YANG DIIZINKAN (WHITELIST: Indonesia NTP Pool) ---
# Daftar server yang diizinkan (dipisahkan spasi)
AUTHORIZED_SERVERS="0.id.pool.ntp.org 1.id.pool.ntp.org 2.id.pool.ntp.org 3.id.pool.ntp.org id.pool.ntp.org"

f_config_file_parameter_chk()
{
l_parameter_name="$1"
l_used_parameter_setting=""
l_value_is_authorized="false"

# 1. Cari file konfigurasi terakhir yang mengatur parameter
while IFS= read -r l_file; do
l_file="$(tr -d '# ' <<< "$l_file")"
l_used_parameter_setting="$(grep -PHs -- '^\h*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
[ -n "$l_used_parameter_setting" ] && break
done < <("$l_analyze_cmd" cat-config "$l_systemd_config_file" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

if [ -n "$l_used_parameter_setting" ]; then
    while IFS=: read -r l_file_name l_file_parameter; do
        while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
            # Hapus spasi untuk perbandingan
            l_file_parameter_name="$(echo "$l_file_parameter_name" | xargs)"
            l_file_parameter_value="$(echo "$l_file_parameter_value" | xargs)"
            if [ -n "$l_file_parameter_value" ]; then
                # Cek Otorisasi Timeserver
                for server in $l_file_parameter_value; do
                    if grep -Pq -- "\b$server\b" <<< "$AUTHORIZED_SERVERS"; then
                        l_value_is_authorized="true"
                        a_out+=(" - Parameter: \"${l_file_parameter_name}\" set to: \"${l_file_parameter_value}\" in file: \"$l_file_name\" (AUTHORIZED)")
                        break # Keluar dari loop server jika satu saja sudah diotorisasi
                    fi
                done

                if [ "$l_value_is_authorized" = "false" ]; then
                    a_out2+=(" - Parameter: \"${l_file_parameter_name}\" set to: \"${l_file_parameter_value}\" in file: \"$l_file_name\" (UNAUTHORIZED - Must be set to a server in $AUTHORIZED_SERVERS)")
                fi

            else
                # Parameter kosong atau dikomentari
                a_out2+=(" - Parameter: \"${l_file_parameter_name}\" is commented out or empty in the file: \"$l_file_name\" and must be set to an authorized timeserver.")
            fi

        done <<< "$l_file_parameter"
    done <<< "$l_used_parameter_setting"
else
    a_out2+=(" - Parameter: \"$l_parameter_name\" is not set in any included file.")
fi
}

while IFS="=" read -r l_parameter_name l_parameter_value; do # Assess and check parameters
l_parameter_name="${l_parameter_name// /}"; l_parameter_value="${l_parameter_value// /}"
l_value_out="${l_parameter_value//-/ through }"; l_value_out="${l_value_out//|/ or }"
l_value_out="$(tr -d '(){}' <<< "$l_value_out")"
f_config_file_parameter_chk "$l_parameter_name"
done < <(printf '%s\n' "${a_parlist[@]}")

# Combine results for CSV output
if [ "${#a_out[@]}" -gt 0 ]; then
    a_output+=("${a_out[@]}"); 
    [ "${#a_out2[@]}" -gt 0 ] && a_output3+=(" ** INFO: Unauthorized/Unset parameters: **" "${a_out2[@]}")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_out2[@]}" -le 0 ] && [ "${#a_out[@]}" -gt 0 ]; then
    # Jika TIDAK ADA yang gagal di a_out2 (tidak kosong/tidak diotorisasi)
    # DAN setidaknya satu server telah berhasil ditemukan di a_out
    RESULT="PASS" 
    NOTES+="PASS: All required parameters are set to authorized timeserver(s). ${a_output[*]}"
else
    # Gagal jika parameter hilang, kosong, atau tidak diotorisasi
    RESULT="FAIL"
    NOTES+="FAIL: Required parameters are missing, empty, or unauthorized. ${a_out2[*]}"
    [ "${#a_out[@]}" -gt 0 ] && NOTES+=" | INFO (Authorized): ${a_out[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}