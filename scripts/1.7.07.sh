#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.7.7"
DESCRIPTION="Ensure GDM disabling automatic mounting of removable media is not overridden"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

check_setting()
{
# $1: setting name (e.g., automount)
# $2: dconf path (e.g., org/gnome/desktop/media-handling)
# $3: setting name for output
grep -Psrilq "^\h*$1\h*=\h*false\b" /etc/dconf/db/local.d/locks/* 2> /dev/null && \
echo "- \"$3\" is locked and set to false" || echo "- \"$3\" is not locked or not set to false"
}

declare -A settings=(
["automount"]="org/gnome/desktop/media-handling"
["automount-open"]="org/gnome/desktop/media-handling"
)

# --- FUNGSI AUDIT LOCKS ---
for setting in "${!settings[@]}"; do
    result=$(check_setting "$setting" "${settings[$setting]}" "$setting")
    if [[ $result == *"is not locked"* || $result == *"not set to false"* ]]; then
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