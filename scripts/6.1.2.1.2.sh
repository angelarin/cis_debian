#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.2.1.2"
DESCRIPTION="Ensure systemd-journal-upload authentication is configured (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_systemd_config_file="systemd/journal-upload.conf"
a_parameters=("URL=^.+$" "ServerKeyFile=^.+$" "ServerCertificateFile=^.+$" "TrustedCertificateFile=^.+$")

f_config_file_parameter_chk()
{
local l_parameter_name="$1" l_parameter_value="$2"
local l_used_parameter_setting=""
local l_file_found="n"

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
            if [ -n "$l_file_parameter_value" ] && ! echo "$l_file_parameter_value" | grep -q '^#'; then
                a_output+=(" - Parameter: \"$l_file_parameter_name\" set to: \"$l_file_parameter_value\" in the file: \"$l_file_name\"")
            fi
        done <<< "$l_file_parameter"
    done <<< "$l_used_parameter_setting"
else
    a_output2+=(" - Parameter: \"$l_parameter_name\" is NOT set in an included file. (May be required for secure remote logging).")
fi
}

for l_input_parameter in "${a_parameters[@]}"; do
    l_parameter_name=$(echo "$l_input_parameter" | cut -d= -f1)
    l_parameter_value=$(echo "$l_input_parameter" | cut -d= -f2)
    f_config_file_parameter_chk "$l_parameter_name" "$l_parameter_value"
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output[@]}" -le 0 ]; then
    NOTES+="FAIL: No remote upload configuration detected. This is a failure if remote logging is required. ${a_output2[*]}"
    RESULT="FAIL"
else
    NOTES+="REVIEW: Authentication parameters collected. ${a_output[*]}"
    [ "${#a_output2[@]}" -gt 0 ] && NOTES+=" | WARNINGS: ${a_output2[*]}"
    NOTES+=" | Action: REVIEW the URL and certificate paths against site policy."
    RESULT="REVIEW"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}