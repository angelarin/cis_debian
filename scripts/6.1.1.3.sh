#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.1.3"
DESCRIPTION="Ensure journald log file rotation is configured (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_systemd_config_file="systemd/journald.conf"
# Mencari parameter rotasi yang memiliki nilai (setidaknya satu karakter non-spasi/hash/newline)
a_parameters=("SystemMaxUse=^.+$" "SystemKeepFree=^.+$" "RuntimeMaxUse=^.+$" "RuntimeKeepFree=^.+$" "MaxFileSec=^.+$")

f_config_file_parameter_chk()
{
local l_parameter_name="$1" l_parameter_value="$2"
local l_used_parameter_setting=""
local l_file_found="n"

# Cari setting parameter dari file yang dimuat oleh systemd-analyze (berdasarkan preseden)
while IFS= read -r l_file; do
    l_file="$(tr -d '# ' <<< "$l_file")"
    l_used_parameter_setting="$(grep -PHs -- '^\h*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
    if [ -n "$l_used_parameter_setting" ]; then
        l_file_found="y"
        break
    fi
done < <("$l_analyze_cmd" cat-config "$l_systemd_config_file" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

if [ "$l_file_found" = "y" ]; then
    while IFS=: read -r l_file_name l_file_parameter; do
        while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
            l_file_parameter_name="${l_file_parameter_name// /}"
            l_file_parameter_value="${l_file_parameter_value// /}"
            if [ -n "$l_file_parameter_value" ]; then
                a_output+=(" - Parameter: \"$l_file_parameter_name\" set to: \"$l_file_parameter_value\" in the file: \"$l_file_name\"")
            fi
        done <<< "$l_file_parameter"
    done <<< "$l_used_parameter_setting"
else
    a_output2+=(" - Parameter: \"$l_parameter_name\" is not set in an included file. It relies on system default settings.")
fi
}

for l_input_parameter in "${a_parameters[@]}"; do
    # Pisahkan nama parameter dan regex nilai
    l_parameter_name=$(echo "$l_input_parameter" | cut -d= -f1)
    l_parameter_value=$(echo "$l_input_parameter" | cut -d= -f2)
    
    f_config_file_parameter_chk "$l_parameter_name" "$l_parameter_value"
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="REVIEW: Log rotation parameters found. ${a_output[*]}"
else
    NOTES+="REVIEW: Some parameters rely on defaults or are missing. ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO (Set): ${a_output[*]}"
fi
NOTES+=" | Action: REVIEW the set values (MaxUse, KeepFree, MaxFileSec) against local site policy for sufficiency."
RESULT="REVIEW"

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}