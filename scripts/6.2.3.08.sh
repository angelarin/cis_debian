#!/usr/bin/env bash

CHECK_ID="6.2.3.8"
DESCRIPTION="Ensure events that modify the systems network environment are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_network() {
    local type=$1 output="$2"
    local found=0
    local found_items=()
    local missing_items=()

    local checks=(
        "/etc/network/interfaces"
        "dir=/etc/network/interfaces.d"
        "dir=/etc/netplan"
    )
    
    for item in "${checks[@]}"; do
        if echo "$output" | grep -Eq "$item"; then
            found=$((found+1))
            found_items+=("$item")
        else
            missing_items+=("$item")
        fi
    done

    # PASS jika menemukan MINIMAL 1 rule jaringan
    if [ "$found" -ge 1 ]; then
        a_output+=(" - $type: Found ($found/3): [${found_items[*]}]. Missing: [${missing_items[*]}].")
        return 1
    else
        a_output2+=(" - $type: No network environment rules found at all.")
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
    NOTES+="PASS: Network environment rules partially or fully met. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing network environment rules. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}