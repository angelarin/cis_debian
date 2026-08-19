#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.1.8"
DESCRIPTION="Ensure udf kernel module is not available"
# -----------------------------------------------------

{
a_output=() a_output2=() a_output3=() l_dl="" l_mod_name="udf"
l_mod_type="fs"
l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"
RESULT="" NOTES=""

f_module_chk()
{
l_dl="y" a_showconfig=()
l_mod_chk_name="$l_mod_name"
while IFS= read -r l_showconfig; do
a_showconfig+=("$l_showconfig")
done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

if ! lsmod | grep "$l_mod_chk_name" &> /dev/null; then
a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
else
a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
fi

if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
a_output+=(" - kernel module: \"$l_mod_name\" is not loadable (install /bin/false or /bin/true)")
else
a_output2+=(" - kernel module: \"$l_mod_name\" is loadable (no install /bin/false or /bin/true found)")
fi

if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
a_output+=(" - kernel module: \"$l_mod_name\" is deny listed (blacklisted)")
else
a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed (no blacklist found)")
fi
}

for l_mod_base_directory in $l_mod_path; do
if [ -d "$l_mod_base_directory/${l_mod_name/-/\/}" ] && [ -n "$(ls -A "$l_mod_base_directory/${l_mod_name/-/\/}")" ]; then
a_output3+=(" - \"$l_mod_base_directory\"")
l_mod_chk_name="$l_mod_name"
[[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
[ "$l_dl" != "y" ] && f_module_chk
else
a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
fi
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output3[@]}" -gt 0 ]; then
    NOTES+="INFO: module $l_mod_name exists in: ${a_output3[*]}"
fi

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+=" | FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}