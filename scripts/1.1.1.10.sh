#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.1.10"
DESCRIPTION="Ensure unused filesystems kernel modules are not available"
# -----------------------------------------------------

{
a_output=(); a_output2=(); a_modprope_config=(); a_excluded=(); a_available_modules=()
a_ignore=("xfs" "vfat" "ext2" "ext3" "ext4")
a_cve_exists=("afs" "ceph" "cifs" "exfat" "fat" "fscache" "fuse" "gfs2")
f_module_chk()
{
l_out2=""; grep -Pq -- "\b$l_mod_name\b" <<< "${a_cve_exists[*]}" && l_out2=" <- CVE exists!"
if ! grep -Pq -- '\bblacklist\h+'"$l_mod_name"'\b' <<< "${a_modprope_config[*]}"; then
a_output2+=(" - Kernel module: \"$l_mod_name\" is not fully disabled $l_out2")
elif ! grep -Pq -- '\binstall\h+'"$l_mod_name"'\h+(\/usr)?\/bin\/(false|true)\b' <<< "${a_modprope_config[*]}"; then
a_output2+=(" - Kernel module: \"$l_mod_name\" is not fully disabled $l_out2")
fi
if lsmod | grep "$l_mod_name" &> /dev/null; then # Check if the module is currently loaded
l_output2+=(" - Kernel module: \"$l_mod_name\" is loaded" "")
fi
}
while IFS= read -r -d $'\0' l_module_dir; do
a_available_modules+=("$(basename "$l_module_dir")")
done < <(find "$(readlink -f /lib/modules/"$(uname -r)"/kernel/fs)" -mindepth 1 -maxdepth 1 -type d ! -empty -print0)
while IFS= read -r l_exclude; do
if grep -Pq -- "\b$l_exclude\b" <<< "${a_cve_exists[*]}"; then
a_output2+=(" - ** WARNING: kernel module: \"$l_exclude\" has a CVE and is currently mounted! **")
elif
grep -Pq -- "\b$l_exclude\b" <<< "${a_available_modules[*]}"; then
a_output+=(" - Kernel module: \"$l_exclude\" is currently mounted - do NOT unload or disable")
fi
! grep -Pq -- "\b$l_exclude\b" <<< "${a_ignore[*]}" && a_ignore+=("$l_exclude")
done < <(findmnt -knD | awk '{print $2}' | sort -u)
while IFS= read -r l_config; do
a_modprope_config+=("$l_config")
done < <(modprobe --showconfig | grep -P '^\h*(blacklist|install)')
for l_mod_name in "${a_available_modules[@]}"; do # Iterate over all filesystem modules
[[ "$l_mod_name" =~ overlay ]] && l_mod_name="${l_mod_name::-2}"
if grep -Pq -- "\b$l_mod_name\b" <<< "${a_ignore[*]}"; then
a_excluded+=(" - Kernel module: \"$l_mod_name\"")
else
f_module_chk
fi
done

# Logika printf asli dihilangkan dan diganti dengan logic output CSV

# --- Modifikasi Output untuk Master Script (Mengganti printf terakhir) ---
NOTES=""

# 1. Tambahkan informasi modul (a_output3) jika ada
if [ "${#a_output3[@]}" -gt 0 ]; then
    NOTES+="INFO: module $l_mod_name exists in: ${a_output3[*]}"
fi

# 2. Tentukan Status dan gabungkan a_output / a_output2
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+=" | FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# 3. Ganti karakter enter/newline/spasi ganda dengan satu spasi untuk output satu baris
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')

# 4. Cetak output dalam format ID|DESKRIPSI|RESULT|NOTES
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
# --------------------------------------------------------------------------
}