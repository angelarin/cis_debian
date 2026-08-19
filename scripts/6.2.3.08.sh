#!/usr/bin/env bash

CHECK_ID="6.2.3.8"
DESCRIPTION="Ensure events that modify the system's network environment are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_network() {
    local type=$1 output="$2"
    local found=0 missing=0

    # Mengecek ketiganya, tapi netplan mungkin tidak selalu ada (opsional di beberapa distro),
    # namun CIS mengharuskannya jika ada. Untuk aman, kita pastikan ketiga pattern ini ada di rule.
    local checks=("/etc/network/interfaces" "dir=/etc/network/interfaces.d" "dir=/etc/netplan")
    
    for item in "${checks[@]}"; do
        if echo "$output" | grep -Eq "$item"; then
            found=$((found+1))
        else
            missing=$((missing+1))
        fi
    done

    if [ "$missing" -eq 0 ]; then
        a_output+=(" - $type: Network environment rules found.")
        return 1
    else
        a_output2+=(" - $type: Network environment rules incomplete.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '\/etc/net')
f_check_network "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '\/etc/net' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_network "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: Network environment rules found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing network environment rules. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}