#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.1.10"
DESCRIPTION="Ensure unused filesystems kernel modules are not available (REVIEW REQUIRED)"
# -----------------------------------------------------

{
a_output=(); a_output2=(); a_modprope_config=(); a_excluded=(); a_available_modules=()
a_ignore=("xfs" "vfat" "ext2" "ext3" "ext4")
a_cve_exists=("afs" "ceph" "cifs" "exfat" "fat" "fscache" "fuse" "gfs2")
RESULT="REVIEW" NOTES=""

f_module_chk()
{
l_out2="";
l_mod_name="$1"
grep -Pq -- "\b$l_mod_name\b" <<< "${a_cve_exists[*]}" && l_out2=" <- CVE exists!"

# 1. Check for blacklist and install/false
if ! grep -Pq -- '\bblacklist\h+'"$l_mod_name"'\b' <<< "${a_modprope_config[*]}" || \
   ! grep -Pq -- '\binstall\h+'"$l_mod_name"'\h+(\/usr)?\/bin\/(false|true)\b' <<< "${a_modprope_config[*]}"; then
    a_output2+=(" - Kernel module: \"$l_mod_name\" is not fully disabled $l_out2")
fi

# 2. Check if the module is currently loaded
if lsmod | grep "$l_mod_name" &> /dev/null; then
    a_output2+=(" - Kernel module: \"$l_mod_name\" is currently loaded! $l_out2")
fi
}

# 1. Populate a_available_modules (All filesystem modules available on system)
while IFS= read -r -d $'\0' l_module_dir; do
a_available_modules+=("$(basename "$l_module_dir")")
done < <(find "$(readlink -f /lib/modules/"$(uname -r)"/kernel/fs)" -mindepth 1 -maxdepth 1 -type d ! -empty -print0 2>/dev/null)

# 2. Add currently mounted filesystems to a_ignore
while IFS= read -r l_exclude; do
if grep -Pq -- "\b$l_exclude\b" <<< "${a_cve_exists[*]}"; then
a_output2+=(" - ** WARNING: kernel module: \"$l_exclude\" has a CVE and is currently mounted! **")
elif
grep -Pq -- "\b$l_exclude\b" <<< "${a_available_modules[*]}"; then
a_output+=(" - Kernel module: \"$l_exclude\" is currently mounted - do NOT unload or disable")
fi
! grep -Pq -- "\b$l_exclude\b" <<< "${a_ignore[*]}" && a_ignore+=("$l_exclude")
done < <(findmnt -knD | awk '{print $2}' | sort -u)

# 3. Populate a_modprope_config (All current blacklist/install configs)
while IFS= read -r l_config; do
a_modprope_config+=("$l_config")
done < <(modprobe --showconfig | grep -P '^\h*(blacklist|install)')

# 4. Iterate over all available modules and run check
for l_mod_name in "${a_available_modules[@]}"; do
# Handle modules with differing filesystem/module names (e.g., overlayfs vs overlay)
[[ "$l_mod_name" =~ overlay ]] && l_mod_name="${l_mod_name::-2}"

if grep -Pq -- "\b$l_mod_name\b" <<< "${a_ignore[*]}"; then
a_excluded+=(" - Kernel module: \"$l_mod_name\"")
else
f_module_chk "$l_mod_name"
fi
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_excluded[@]}" -gt 0 ]; then
    NOTES+="INFO: The following modules were skipped because they are currently mounted or manually ignored: ${a_excluded[*]}"
fi

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+=" | PASS: No unused filesystem kernel modules found to be loaded or loadable. ${a_output[*]}"
else
    RESULT="REVIEW" # Set ke REVIEW karena kebijakan aslinya menggunakan REVIEW
    NOTES+=" | REVIEW: The following issues require review: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO (Correctly set): ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}