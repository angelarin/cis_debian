#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.7.5"
DESCRIPTION="Ensure GDM screen locks cannot be overridden"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

f_check_setting()
{
# $1: setting name (e.g., idle-delay)
# $2: dconf path (e.g., /org/gnome/desktop/session/idle-delay)
# $3: setting name for output
grep -Psrilq -- "^\h*$2\b" /etc/dconf/db/local.d/locks/* && \
echo "- \"$3\" is locked" || echo "- \"$3\" is not locked or not set"
}

declare -A settings=(
["idle-delay"]="/org/gnome/desktop/session/idle-delay"
["lock-delay"]="/org/gnome/desktop/screensaver/lock-delay"
)

# --- FUNGSI AUDIT LOCKS ---
for setting in "${!settings[@]}"; do
    result=$(f_check_setting "$setting" "${settings[$setting]}" "$setting")
    if [[ $result == *"is not locked"* ]]; then
        a_output2+=("$result")
    else
        a_output+=("$result")
    fi
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: All necessary settings are locked. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set (LOCKED): ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}