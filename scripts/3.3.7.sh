#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="3.3.7"
DESCRIPTION="Ensure reverse path filtering is enabled"
# -----------------------------------------------------

{
a_output=(); a_output2=(); l_ipv6_disabled=""
a_parlist=("net.ipv4.conf.all.rp_filter=1"
"net.ipv4.conf.default.rp_filter=1")
l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"
l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"
RESULT="" NOTES=""

f_ipv6_chk()
{
l_ipv6_disabled="no"
! grep -Pqs -- '^\h*0\b' /sys/module/ipv6/parameters/disable 2>/dev/null && l_ipv6_disabled="yes"
if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\b" && \
   sysctl net.ipv6.conf.default.disable_ipv6 2>/dev/null | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\b"; then
l_ipv6_disabled="yes"
fi
}

f_kernel_parameter_chk()
{
l_running_parameter_value="$(sysctl "$l_parameter_name" 2>/dev/null | awk -F= '{print $2}' | xargs)" # Check running configuration
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
l_kpar="$(grep -Po "^\h*$l_parameter_name\b" "$l_ufwscf" | xargs)"; l_kpar="${l_kpar//\//.}"
[ "$l_kpar" = "$l_parameter_name" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
fi

if (( ${#A_out[@]} > 0 )); then # Assess output from files
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

while IFS="=" read -r l_parameter_name l_parameter_value; do # Assess and check parameters
l_parameter_name="${l_parameter_name// /}"; l_parameter_value="${l_parameter_value// /}"
l_value_out="${l_parameter_value//-/ through }"; l_value_out="${l_value_out//|/ or }"
l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

if grep -q '^net.ipv6.' <<< "$l_parameter_name"; then
    [ -z "$l_ipv6_disabled" ] && f_ipv6_chk
    if [ "$l_ipv6_disabled" = "yes" ]; then
        a_output+=(" - IPv6 is disabled on the system, \"$l_parameter_name\" is not applicable")
    else
        f_kernel_parameter_chk
    fi
else
    f_kernel_parameter_chk
fi
done < <(printf '%s\n' "${a_parlist[@]}")

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}