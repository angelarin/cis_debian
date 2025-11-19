#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="3.1.2"
DESCRIPTION="Ensure wireless interfaces are disabled"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

module_chk()
{
local l_mname="$1"
local l_mod_output=""
local l_mod_output2=""

# Check how module will be loaded
l_loadable="$(modprobe -n -v "$l_mname" 2>/dev/null)"
if grep -Pq -- '^\h*install \/bin\/(true|false)' <<< "$l_loadable"; then
    l_mod_output=" - module: \"$l_mname\" is not loadable (install /bin/false or /bin/true found)."
else
    l_mod_output2=" - module: \"$l_mname\" is loadable (no install /bin/false or /bin/true found)."
fi

# Check is the module currently loaded
if ! lsmod | grep "$l_mname" > /dev/null 2>&1; then
    l_mod_output+=" - module: \"$l_mname\" is not loaded."
else
    l_mod_output2+=" - module: \"$l_mname\" is loaded."
fi

# Check if the module is deny listed
if modprobe --showconfig | grep -Pq -- "^\h*blacklist\h+$l_mname\b"; then
    l_mod_output+=" - module: \"$l_mname\" is deny listed (blacklisted in: $(grep -Pl -- "^\h*blacklist\h+$l_mname\b" /etc/modprobe.d/* 2>/dev/null))."
else
    l_mod_output2+=" - module: \"$l_mname\" is not deny listed."
fi

# Append results globally
if [ -n "$l_mod_output2" ]; then
    a_output2+=("Wireless module $l_mname failed checks: $l_mod_output2")
    [ -n "$l_mod_output" ] && a_output+=("Wireless module $l_mname set correctly: $l_mod_output")
else
    a_output+=("Wireless module $l_mname passed all checks: $l_mod_output")
fi
}

# --- FUNGSI AUDIT INTERFACE WIRELESS ---
if [ -n "$(find /sys/class/net/*/ -type d -name wireless 2>/dev/null)" ]; then
    # Identifikasi nama driver modul wireless yang terpasang
    l_dname=$(for driverdir in $(find /sys/class/net/*/ -type d -name wireless 2>/dev/null | xargs -r dirname); do 
        basename "$(readlink -f "$driverdir"/device/driver/module 2>/dev/null)";
    done | sort -u)
    
    if [ -n "$l_dname" ]; then
        a_output+=(" - Wireless NIC(s) found. Checking modules: $l_dname")
        for l_mname in $l_dname; do
            module_chk "$l_mname"
        done
    else
        a_output+=(" - Wireless interfaces found, but module drivers could not be identified.")
    fi
else
    a_output+=(" - System has no detectable wireless NICs installed.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set/Info: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}