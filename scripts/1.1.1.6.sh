#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.1.6"
DESCRIPTION="Ensure overlayfs kernel module is not available"
# -----------------------------------------------------

{
a_output=() a_output2=() a_output3=() l_mod_name="overlayfs"
l_mod_type="fs"
# Gunakan find untuk mengatasi wildcard, lalu sort dan join dengan newlines
l_mod_path="$(find /lib/modules/ -type d -path '*/kernel/fs' 2>/dev/null | sort -u | paste -sd ' ' -)"
RESULT="" NOTES=""
l_mod_chk_name="$l_mod_name"
l_module_exists="n"

f_module_chk()
{
    l_mod_chk_name="$1"
    a_showconfig=()
    while IFS= read -r l_showconfig; do
        a_showconfig+=("$l_showconfig")
    done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b' 2>/dev/null)

    # 1. Cek: Modul tidak dimuat
    if ! lsmod | grep -q "$l_mod_chk_name" 2>/dev/null; then
        a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
    fi

    # 2. Cek: Modul tidak dapat dimuat (install /bin/false atau /bin/true)
    if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
        a_output+=(" - kernel module: \"$l_mod_name\" is not loadable (install /bin/false or /bin/true)")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is loadable (no install /bin/false or /bin/true found)")
    fi

    # 3. Cek: Modul deny listed (blacklisted)
    if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
        a_output+=(" - kernel module: \"$l_mod_name\" is deny listed (blacklisted)")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed (no blacklist found)")
    fi
}

# 1. Cek keberadaan file modul di sistem
for l_mod_base_directory in $l_mod_path; do
    if [ -d "$l_mod_base_directory/${l_mod_name/-/\/}" ] && [ -n "$(ls -A "$l_mod_base_directory/${l_mod_name/-/\/}" 2>/dev/null)" ]; then
        a_output3+=(" - \"$l_mod_base_directory\"")
        l_module_exists="y"
    fi
done

# 2. Jika modul ada, jalankan pemeriksaan keamanan HANYA SEKALI
if [ "$l_module_exists" = "y" ]; then
    l_mod_chk_name="$l_mod_name" 
    [[ "$l_mod_name" =~ overlay ]] && l_mod_chk_name="${l_mod_name::-2}"
    
    f_module_chk "$l_mod_chk_name"
else
    a_output+=(" - kernel module: \"$l_mod_name\" not found on disk. Audit N/A.")
fi

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