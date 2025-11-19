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

f_config_file_parameter_chk()
{
l_used_parameter_setting=""
# Use systemd-analyze to find the last file where the parameter is set
while IFS= read -r l_file; do
l_file="$(tr -d '# ' <<< "$l_file")"
l_used_parameter_setting="$(grep -PHs -- '^\h*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
[ -n "$l_used_parameter_setting" ] && break
done < <("$l_analyze_cmd" cat-config "$l_systemd_config_file" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

if [ -n "$l_used_parameter_setting" ]; then
while IFS=: read -r l_file_name l_file_parameter; do
while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
# Remove spaces for comparison
l_file_parameter_name="${l_file_parameter_name// /}"
l_file_parameter_value="${l_file_parameter_value// /}"
if [ -n "$l_file_parameter_value" ]; then
    a_out+=(" - Parameter: \"${l_file_parameter_name}\" set to: \"${l_file_parameter_value}\" in the file: \"$l_file_name\"")
else
    a_out2+=(" - Parameter: \"${l_file_parameter_name}\" is commented out or empty in the file: \"$l_file_name\" and should be set to: authorized timeserver(s)")
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
f_config_file_parameter_chk
done < <(printf '%s\n' "${a_parlist[@]}")

# Combine results for CSV output
if [ "${#a_out[@]}" -gt 0 ]; then
    a_output+=("${a_out[@]}"); 
    [ "${#a_out2[@]}" -gt 0 ] && a_output3+=(" ** INFO: Unset/Commented parameters: **" "${a_out2[@]}")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    # Jika tidak ada kesalahan mendasar (uncommented/empty)
    RESULT="REVIEW" # Set ke REVIEW karena harus dibandingkan dengan site policy
    NOTES+="INFO: Parameters collected. ${a_output[*]}"
    NOTES+=" | Action: REVIEW parameter values against local site policy for approval."
else
    # Jika ada masalah mendasar (uncommented/empty)
    RESULT="FAIL"
    NOTES+="FAIL: Required parameters are missing or commented out. ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO (Collected): ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}