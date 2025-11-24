#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.2.7"
DESCRIPTION="Ensure system accounts do not have a valid login shell"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
EXCLUDED_USERS="root|halt|sync|shutdown|nfsnobody"

# 1. Bangun daftar shell yang valid
# Filter /etc/shells, buang 'nologin', escape, dan gabungkan dengan '|'
l_valid_shells="^($(awk -F\/ '$NF != "nologin" {print}' /etc/shells 2>/dev/null | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"

if [ "$l_valid_shells" = "^()$" ]; then
    a_output2+=(" - Could not determine valid shells from /etc/shells.")
    RESULT="FAIL"
else
    a_output+=(" - Valid shells found: ${l_valid_shells//\\/}")

    # 2. Cek akun sistem yang memiliki shell valid
    # Akun sistem: UID < UID_MIN ATAU UID = 65534 (nobody)
    L_UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)
    [ -z "$L_UID_MIN" ] && L_UID_MIN=1000 # Fallback jika login.defs tidak tersedia

    L_VIOLATIONS=$(awk -v pat="$l_valid_shells" -v uid_min="$L_UID_MIN" -F: \
    '($1!~/^('"$EXCLUDED_USERS"')$/ && ($3<uid_min || $3 == 65534) && $NF ~ pat) \
    {print "Service account: \"" $1 "\" has a valid shell: " $7}' /etc/passwd 2>/dev/null)

    if [ -n "$L_VIOLATIONS" ]; then
        RESULT="FAIL"
        a_output2+=(" - Detected service account(s) with a valid login shell: ${L_VIOLATIONS//$'\n'/ | }")
    else
        a_output+=(" - No service accounts detected with a valid login shell.")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}