#!/usr/bin/env bash

CHECK_ID="6.2.3.22"
DESCRIPTION="Ensure session initiation information is collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_session() {
    local type=$1 output="$2"
    local found=0
    local found_items=()
    local missing_in_os=()
    local missing_in_audit=()

    # Daftar file OS dan pattern rule auditd-nya
    local checks=(
        "/var/run/utmp:(path=/var/run/utmp|-w /var/run/utmp)"
        "/var/log/wtmp:(path=/var/log/wtmp|-w /var/log/wtmp)"
        "/var/log/btmp:(path=/var/log/btmp|-w /var/log/btmp)"
    )

    for item in "${checks[@]}"; do
        local os_path="${item%%:*}"
        local rule_pattern="${item##*:}"

        if echo "$output" | grep -Eq "$rule_pattern"; then
            found=$((found+1))
            found_items+=("$os_path")
        else
            # Pisahkan file yang memang tidak ada di OS dengan file yang ada tapi rule-nya bolong
            if [ ! -e "$os_path" ]; then
                missing_in_os+=("$os_path")
            else
                missing_in_audit+=("$os_path")
            fi
        fi
    done

    # Lulus asalkan minimal ada 1 rule yang berhasil dipasang
    if [ "$found" -ge 1 ]; then
        local msg=" - $type: Found ($found/3): [${found_items[*]}]."
        if [ ${#missing_in_os[@]} -gt 0 ]; then
            msg+=" Note: File not in OS [${missing_in_os[*]}]."
        fi
        if [ ${#missing_in_audit[@]} -gt 0 ]; then
            msg+=" Note: Missing rule [${missing_in_audit[*]}]."
        fi
        a_output+=("$msg")
        return 1
    else
        a_output2+=(" - $type: No session initiation rules found at all.")
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
    NOTES+="PASS: Session initiation rules partially or fully met. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing session initiation rules. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}