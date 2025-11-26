#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.3.3"
DESCRIPTION="Ensure journald is configured to send logs to rsyslog (ForwardToSyslog=yes)"
# -----------------------------------------------------

{
a_output=() a_output2=() l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_systemd_config_file="systemd/journald.conf"
a_parameters=("ForwardToSyslog=yes")
RESULT="PASS" NOTES=""

# --- 1. AUDIT FORWARDTOSYSLOG ---
f_config_file_parameter_chk()
{
l_used_parameter_setting=""
l_systemdsysctl_analyze="$(readlink -f /bin/systemd-analyze)"

while IFS= read -r l_file; do
l_file="$(tr -d '# ' <<< "$l_file")"
l_used_parameter_setting="$(grep -PHs -- '^\h*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
[ -n "$l_used_parameter_setting" ] && break
done < <("$l_systemdsysctl_analyze" cat-config "$l_systemd_config_file" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

if [ -n "$l_used_parameter_setting" ]; then
while IFS=: read -r l_file_name l_file_parameter; do
while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
if grep -Pq -- "$l_parameter_value" <<< "$l_file_parameter_value"; then
a_output+=(" - Parameter: \"${l_file_parameter_name// /}\"" " correctly set to: \"${l_file_parameter_value// /}\"" " in the file: \"$l_file_name\"")
else
a_output2+=(" - Parameter: \"${l_file_parameter_name// /}\"" " incorrectly set to: \"${l_file_parameter_value// /}\"" " in the file: \"$l_file_name\"" " Should be set to: \"$l_value_out\"")
fi
done <<< "$l_file_parameter"
done <<< "$l_used_parameter_setting"
else
a_output2+=(" - Parameter: \"$l_parameter_name\" is not set in an included file" " *** Note: \"$l_parameter_name\" May be set in a file that's ignored by load procedure ***")
fi
}

for l_input_parameter in "${a_parameters[@]}"; do
while IFS="=" read -r l_parameter_name l_parameter_value; do
l_parameter_name="${l_parameter_name// /}";
l_parameter_value="${l_parameter_value// /}"
l_value_out="${l_parameter_value//-/ through }";
l_value_out="${l_value_out//|/ or }"
l_value_out="$(tr -d '(){}' <<< "$l_value_out")"
f_config_file_parameter_chk
done <<< "$l_input_parameter"
done

# --- 2. AUDIT STATUS LAYANAN ---
L_SERVICE_STATUS=$(systemctl list-units --type service 2>/dev/null | grep -P -- '(rsyslog|journald)')
if echo "$L_SERVICE_STATUS" | grep -q 'rsyslog\.service.*active' && echo "$L_SERVICE_STATUS" | grep -q 'systemd-journald\.service.*active'; then
    a_output+=(" - Both rsyslog and journald services are loaded and active.")
else
    a_output2+=(" - One or both logging services (rsyslog/journald) are not active. Status: ${L_SERVICE_STATUS//$'\n'/ | }")
    # Jika konfigurasi ForwardToSyslog PASS, status akhir adalah PASS/FAIL berdasarkan status layanan.
    if [ "${#a_output2[@]}" -le 1 ]; then RESULT="PASS"; else RESULT="FAIL"; fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
    RESULT="FAIL"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}