#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.5.3"
DESCRIPTION="Ensure core dumps are restricted (* hard core 0 and fs.suid_dumpable=0)"
# -----------------------------------------------------

{
a_output=() a_output2=() a_parlist=("fs.suid_dumpable=0")
l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"
l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"
RESULT="" NOTES=""

# 1. FUNGSIONALITAS KERNEL PARAMETER CHECK (Diambil dari audit sebelumnya)
f_kernel_parameter_chk()
{
l_running_parameter_value="$(sysctl "$l_parameter_name" | awk -F= '{print $2}' | xargs)" # Check running configuration
if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_running_parameter_value"; then
a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_running_parameter_value\" in the running configuration")
else
a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_running_parameter_value\" in the running configuration and should have a value of: \"$l_value_out\"")
fi

unset A_out; declare -A A_out # Check durable setting (files)
while read -r l_out; do
if [ -n "$l_out" ]; then
if [[ $l_out =~ ^\s*# ]]; then l_file="${l_out//# /}"; else l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"; [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_file"); fi
fi
done < <("$l_systemdsysctl" --cat-config 2>/dev/null | grep -Po '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

if [ -n "$l_ufwscf" ]; then # Account for systems with UFW
l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"; l_kpar="${l_kpar//\//.}"; [ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
fi

if (( ${#A_out[@]} > 0 )); then
while IFS="=" read -r l_fkpname l_file_parameter_value; do
l_fkpname="${l_fkpname// /}"; l_file_parameter_value="${l_file_parameter_value// /}"
if grep -Pq -- '\b'"$l_parameter_value"'\b' <<< "$l_file_parameter_value"; then
a_output+=(" - \"$l_parameter_name\" is correctly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"")
else
a_output2+=(" - \"$l_parameter_name\" is incorrectly set to \"$l_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value of: \"$l_value_out\"")
fi
done < <(grep -Po -- "^\h*$l_parameter_name\h*=\h*\H+" "${A_out[@]}")
else
a_output2+=(" - \"$l_parameter_name\" is not set in an included file ** Note: \"$l_parameter_name\" May be set in a file that's ignored by load procedure **")
fi
}

# Jalankan Kernel Parameter Check
while IFS="=" read -r l_parameter_name l_parameter_value; do
l_parameter_name="${l_parameter_name// /}"; l_parameter_value="${l_parameter_value// /}"
l_value_out="${l_parameter_value//-/ through }"; l_value_out="${l_value_out//|/ or }"
l_value_out="$(tr -d '(){}' <<< "$l_value_out")"
f_kernel_parameter_chk
done < <(printf '%s\n' "${a_parlist[@]}")


# 2. AUDIT PAM LIMITS (* hard core 0)
L_LIMITS_CONF=$(grep -Ps -- '^\h*\*\h+hard\h+core\h+0\b' /etc/security/limits.conf /etc/security/limits.d/*)
if [ -n "$L_LIMITS_CONF" ]; then
    a_output+=(" - Core hard limit (* hard core 0) is correctly set via limits.conf/limits.d.")
    a_output+=(" - Output: $L_LIMITS_CONF")
else
    a_output2+=(" - Core hard limit (* hard core 0) is NOT set or missing.")
fi

# 3. AUDIT systemd-coredump INSTALLATION
L_COREDUMP_STATUS=$(systemctl list-unit-files 2>/dev/null | grep coredump)
if [ -n "$L_COREDUMP_STATUS" ]; then
    a_output2+=(" - WARNING: systemd-coredump appears to be installed/active. Review core dump retention policy.")
    a_output2+=(" - Output: $L_COREDUMP_STATUS")
else
    a_output+=(" - systemd-coredump does not appear to be installed.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
elif [ "${#a_output2[@]}" -eq 1 ] && echo "${a_output2[*]}" | grep -q "systemd-coredump"; then
    # Jika satu-satunya kegagalan adalah systemd-coredump, anggap sebagai Review/Info karena batasnya mungkin diabaikan.
    RESULT="REVIEW"
    NOTES+="REVIEW: Core restriction parameters set correctly, but systemd-coredump is installed. ${a_output[*]} | WARNING: ${a_output2[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}