#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.1.9"
DESCRIPTION="Ensure firewire-core kernel module is not available"
# -----------------------------------------------------

{
a_output=() a_output2=() a_output3=() l_dl="" l_mod_name="firewire-core"
l_mod_type="drivers"
# Mencari path module di dalam direktori drivers
l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"
RESULT="" NOTES=""

f_module_chk()
{
    l_dl="y" a_showconfig=()
    l_mod_chk_name="$l_mod_name"
    
    # Mengambil konfigurasi modprobe untuk pengecekan install/blacklist
    while IFS= read -r l_showconfig; do
        a_showconfig+=("$l_showconfig")
    done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_chk_name//-/_}"'\b')

    # 1. Cek apakah module sedang terload di kernel (lsmod)
    if ! lsmod | grep "$l_mod_chk_name" &> /dev/null; then
        a_output+=(" - kernel module: \"$l_mod_name\" is not loaded")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is loaded")
    fi

    # 2. Cek apakah module diset 'install /bin/true' atau 'false' (tidak bisa di-load)
    if grep -Pq -- '\binstall\h+'"${l_mod_chk_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
        a_output+=(" - kernel module: \"$l_mod_name\" is not loadable (install /bin/false or /bin/true)")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is loadable (no install /bin/false or /bin/true found)")
    fi

    # 3. Cek apakah module masuk dalam daftar blacklist
    if grep -Pq -- '\bblacklist\h+'"${l_mod_chk_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
        a_output+=(" - kernel module: \"$l_mod_name\" is deny listed (blacklisted)")
    else
        a_output2+=(" - kernel module: \"$l_mod_name\" is not deny listed (no blacklist found)")
    fi
}

# Cek keberadaan file module fisik di sistem
for l_mod_base_directory in $l_mod_path; do
    # firewire-core biasanya ada di drivers/firewire/firewire-core.ko
    # Logic ${l_mod_name/-/\/} akan mengubah firewire-core menjadi firewire/core untuk pencarian folder
    if [ -d "$l_mod_base_directory/${l_mod_name/-/\/}" ] || [ -f "$l_mod_base_directory/firewire/${l_mod_name//-/_}.ko" ]; then
        a_output3+=(" - \"$l_mod_base_directory\"")
        [ "$l_dl" != "y" ] && f_module_chk
    fi
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---

# Jika module tidak ditemukan di direktori kernel manapun, otomatis PASS
if [ "${#a_output3[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES="PASS: kernel module \"$l_mod_name\" does not exist on the system"
else
    # Jika module ada, cek apakah mitigasi (blacklist & not loadable) sudah terpenuhi
    if [ "${#a_output2[@]}" -le 0 ]; then
        RESULT="PASS"
        NOTES="INFO: module exists but is disabled | PASS: ${a_output[*]}"
    else
        RESULT="FAIL"
        NOTES="FAIL: module exists and is not properly disabled | Reason(s): ${a_output2[*]}"
        [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
    fi
fi

# Bersihkan karakter newline untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}