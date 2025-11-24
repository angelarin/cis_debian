#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.1.6"
DESCRIPTION="Ensure all users last password change date is in the past"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
CURRENT_EPOCH=$(date +%s)
VIOLATION_FOUND=0

# --- FUNGSI AUDIT PASSWORD CHANGE DATE ---
while IFS= read -r l_user; do
    # Dapatkan tanggal perubahan kata sandi terakhir
    LAST_CHANGE_DATE_STR=$(chage --list "$l_user" 2>/dev/null | grep '^Last password change' | cut -d: -f2 | xargs)
    
    # Lewati jika kata sandi tidak diatur ("never")
    if [[ "$LAST_CHANGE_DATE_STR" != "never" ]] && [[ -n "$LAST_CHANGE_DATE_STR" ]]; then
        # Konversi tanggal ke epoch seconds
        l_change_epoch=$(date -d "$LAST_CHANGE_DATE_STR" +%s 2>/dev/null)
        
        # Bandingkan dengan waktu saat ini
        if [[ "$l_change_epoch" -gt "$CURRENT_EPOCH" ]]; then
            a_output2+=(" - User: \"$l_user\" last password change was in the FUTURE: \"$LAST_CHANGE_DATE_STR\"")
            VIOLATION_FOUND=1
        fi
    fi
done < <(awk -F: '$2~/^\$.+\$/{print $1}' /etc/shadow 2>/dev/null)

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$VIOLATION_FOUND" -eq 0 ]; then
    a_output+=(" - All users with passwords have their last password change date correctly set to the past.")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Found users whose last password change date is set in the future. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}