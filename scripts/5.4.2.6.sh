#!/usr/bin/env bash

CHECK_ID="5.4.2.6"
DESCRIPTION="Ensure root user umask is configured (umask 0027 or more restrictive)"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILES="/root/.bash_profile /root/.bashrc /root/.profile"
MAX_ALLOWED_UMASK=0077

L_CONFIGURED_UMASK=""

for file in $TARGET_FILES; do
    if [ -f "$file" ]; then
        L_OUTPUT=$(grep -Psi -- '^\h*umask\h+\H+' "$file" 2>/dev/null)
        if [ -n "$L_OUTPUT" ]; then
            L_CONFIGURED_UMASK=$(echo "$L_OUTPUT" | tail -n 1 | awk '{print $2}')
            a_output+=(" - Found umask setting in $file: $L_CONFIGURED_UMASK")
        fi
    fi
done

if [ -z "$L_CONFIGURED_UMASK" ]; then
    a_output+=(" - Root user umask is NOT explicitly set in standard configuration files. Relying on default system umask.")
else
    UMASK_VALUE_DECIMAL=$(( 8#$L_CONFIGURED_UMASK ))
    if [ $(( $UMASK_VALUE_DECIMAL & 8#0027 )) -ne 8#0027 ]; then
         a_output2+=(" - Configured umask ($L_CONFIGURED_UMASK) is NOT restrictive enough (Does not restrict group write and/or other rwx fully). Recommended minimum is 0027.")
         RESULT="FAIL"
    else
        a_output+=(" - Configured umask ($L_CONFIGURED_UMASK) enforces appropriate file permissions (>= 0027).")
    fi
fi

if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}