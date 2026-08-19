#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.2.9"
DESCRIPTION="Ensure local interactive user home directories are configured (exist owner mode <= 750)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
l_heout2="" l_hoout2="" l_haout2=""
l_mask='0027' # Mask untuk 0750
l_max="$( printf '%o' $(( 0777 & ~$l_mask)) )" # 750

# Dapatkan daftar user interaktif lokal (shell bukan nologin)
l_valid_shells="^($( awk -F\/ '$NF != "nologin" {print}' /etc/shells 2>/dev/null | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"
a_uarr=()
while read -r l_epu l_eph; do
    a_uarr+=("$l_epu:$l_eph")
done <<< "$(awk -v pat="$l_valid_shells" -F: '$(NF) ~ pat { print $1 " " $(NF-1) }' /etc/passwd 2>/dev/null)"


# --- FUNGSI AUDIT PER USER ---
for user_home in "${a_uarr[@]}"; do
    l_user=$(echo "$user_home" | cut -d: -f1)
    l_home=$(echo "$user_home" | cut -d: -f2)

    if [ -d "$l_home" ]; # 1. Home directory exist
        then
        # Ambil owner dan mode
        while read -r l_own l_mode; do
            # Cek 2. Owner
            if [ "$l_user" != "$l_own" ]; then
                l_hoout2="$l_hoout2\n - User: \"$l_user\" Home \"$l_home\" is owned by: \"$l_own\" (Should be $l_user)"
            fi
            
            # Cek 3. Mode (0750 atau lebih ketat)
            if [ $(( l_mode & l_mask )) -gt 0 ]; then
                l_haout2="$l_haout2\n - User: \"$l_user\" Home \"$l_home\" is mode: \"$l_mode\" (Should be mode: \"$l_max\" or more restrictive)"
            fi
        done <<< "$(stat -Lc '%U %#a' "$l_home" 2>/dev/null)"
    else
        # Home directory does NOT exist
        l_heout2="$l_heout2\n - User: \"$l_user\" Home \"$l_home\" Does NOT exist"
    fi
done

# --- Assess Final Result ---
if [ -z "$l_heout2" ]; then
    a_output+=(" - home directories exist")
else
    RESULT="FAIL"
    a_output2+=("Home Directory Existence Failures: ${l_heout2//$'\n'/ | }")
fi

if [ -z "$l_hoout2" ]; then
    a_output+=(" - own their home directory")
else
    RESULT="FAIL"
    a_output2+=("Home Directory Ownership Failures: ${l_hoout2//$'\n'/ | }")
fi

if [ -z "$l_haout2" ]; then
    a_output+=(" - home directories are mode: \"$l_max\" or more restrictive")
else
    RESULT="FAIL"
    a_output2+=("Home Directory Permissions Failures: ${l_haout2//$'\n'/ | }")
fi

if [ "$RESULT" = "PASS" ]; then
    a_output+=(" - All local interactive users comply.")
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