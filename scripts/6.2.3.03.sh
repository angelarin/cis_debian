#!/usr/bin/env bash

CHECK_ID="6.2.3.3"
DESCRIPTION="Ensure events that modify the sudo log file are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# Cari konfigurasi logfile sudo
SUDO_LOGFILE=$(grep -rPsi "^\h*Defaults\h+([^#]+,\h*)?logfile\h*=\h*(\"|\')?\H+(\"|\')?(,\h*\H+\h*)*\h*(#.*)?$" /etc/sudoers* 2>/dev/null | sed -n 's/.*logfile\s*=\s*"\?\([^",[:space:]]\+\).*/\1/p' | head -n 1)

if [ -z "$SUDO_LOGFILE" ]; then
    RESULT="FAIL"
    NOTES="FAIL: Custom sudo logfile is not configured in /etc/sudoers."
else
    # Escaping path untuk regex grep
    ESCAPED_LOG=$(echo "$SUDO_LOGFILE" | sed 's/\//\\\/g')
    
    f_check_sudolog() {
        local type=$1 output="$2"
        if echo "$output" | grep -Eq "(path=$SUDO_LOGFILE.*perm=wa|-w $SUDO_LOGFILE.*-p wa)"; then
            a_output+=(" - $type: Rule for $SUDO_LOGFILE found.")
            return 1
        else
            a_output2+=(" - $type: Rule for $SUDO_LOGFILE is missing.")
            return 0
        fi
    }

    RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- "$ESCAPED_LOG")
    f_check_sudolog "loaded" "$RUNNING"
    LOADED_OK=$?

    DISK=$(grep -hPs -- "$ESCAPED_LOG" /etc/audit/rules.d/*.rules 2>/dev/null)
    f_check_sudolog "disk" "$DISK"
    DISK_OK=$?

    if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
        NOTES+="PASS: Sudo logfile ($SUDO_LOGFILE) is monitored. ${a_output[*]}"
    else
        RESULT="FAIL"
        NOTES+="FAIL: Audit rule for sudo logfile missing. ${a_output2[*]}"
    fi
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}