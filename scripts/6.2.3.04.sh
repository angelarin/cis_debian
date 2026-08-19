#!/usr/bin/env bash

CHECK_ID="6.2.3.4"
DESCRIPTION="Ensure events that modify date and time information are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
ARCHS=("b32" "b64")

f_check_time() {
    local type=$1 output_sys="$2" output_file="$3"
    local found_adj=0 found_clock=0 found_local=0

    # Periksa System Calls berdasarkan Arsitektur
    for arch in "${ARCHS[@]}"; do
        if echo "$output_sys" | grep -q "arch=${arch}" && echo "$output_sys" | grep -q "adjtimex,settimeofday"; then
            found_adj=$((found_adj + 1))
        fi
        if echo "$output_sys" | grep -q "arch=${arch}" && echo "$output_sys" | grep -q "clock_settime" && echo "$output_sys" | grep -q "a0=0x0"; then
            found_clock=$((found_clock + 1))
        fi
    done

    # Periksa monitoring file /etc/localtime
    if echo "$output_file" | grep -Eq "(path=/etc/localtime.*perm=wa|-w /etc/localtime.*-p wa)"; then
        found_local=1
    fi

    local rules_ok=1
    if [ "$found_adj" -ge 2 ] && [ "$found_clock" -ge 2 ]; then
        a_output+=(" - $type: Syscalls rules found.")
    else
        a_output2+=(" - $type: Syscalls rules incomplete.")
        rules_ok=0
    fi

    if [ "$found_local" -eq 1 ]; then
        a_output+=(" - $type: /etc/localtime rule found.")
    else
        a_output2+=(" - $type: /etc/localtime rule missing.")
        rules_ok=0
    fi

    return $rules_ok
}

RUN_SYS=$(auditctl -l 2>/dev/null | grep -Ps -- '(adjtimex|settimeofday|clock_settime)')
RUN_FILE=$(auditctl -l 2>/dev/null | grep -Ps -- '^\h*[^#\n\r]+\h*\/etc\/localtime')
f_check_time "loaded" "$RUN_SYS" "$RUN_FILE"
LOADED_OK=$?

DSK_SYS=$(grep -hPs -- '(adjtimex|settimeofday|clock_settime)' /etc/audit/rules.d/*.rules 2>/dev/null)
DSK_FILE=$(grep -hPs -- '^\h*[^#\n\r]+\h*\/etc\/localtime' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_time "disk" "$DSK_SYS" "$DSK_FILE"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: Time modification rules found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Time modification rules are incomplete. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}