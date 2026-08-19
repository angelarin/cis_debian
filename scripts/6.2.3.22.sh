#!/usr/bin/env bash

CHECK_ID="6.2.3.22"
DESCRIPTION="Ensure session initiation information is collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_session() {
    local type=$1 output="$2"
    local has_utmp=0 has_wtmp=0 has_btmp=0

    # Mencakup format file .rules (-F path) dan kompatibilitas ke belakang (-w)
    if echo "$output" | grep -Eq "(path=/var/run/utmp -F perm=wa|-w /var/run/utmp -p wa)"; then has_utmp=1; fi
    if echo "$output" | grep -Eq "(path=/var/log/wtmp -F perm=wa|-w /var/log/wtmp -p wa)"; then has_wtmp=1; fi
    if echo "$output" | grep -Eq "(path=/var/log/btmp -F perm=wa|-w /var/log/btmp -p wa)"; then has_btmp=1; fi

    if [ "$has_utmp" -eq 1 ] && [ "$has_wtmp" -eq 1 ] && [ "$has_btmp" -eq 1 ]; then
        a_output+=(" - $type: utmp, wtmp, btmp rules found.")
        return 1
    else
        a_output2+=(" - $type: utmp, wtmp, or btmp rules missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '(\/var\/run\/utmp|\/var\/log\/wtmp|\/var\/log\/btmp)')
f_check_session "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '(\/var\/run\/utmp|\/var\/log\/wtmp|\/var\/log\/btmp)' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_session "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: Session initiation rules found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing session initiation rules. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}