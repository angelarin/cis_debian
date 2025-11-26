#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.4.5"
DESCRIPTION="Ensure audit configuration files mode is configured (mode <= 0640)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
l_perm_mask="0137" # Mask 0137 = Group/Other Write/Execute, Other Read
l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )) )" # 0640

# --- FUNGSI AUDIT MODE CONFIG FILES ---
# Mencari file .conf dan .rules di /etc/audit/
while IFS= read -r -d $'\0' l_fname; do
    l_mode=$(stat -Lc '%#a' "$l_fname")
    
    # Cek apakah mode saat ini lebih longgar dari 0640
    if [ $(( "$l_mode" & "$l_perm_mask" )) -gt 0 ]; then
        a_output2+=(" - File: \"$l_fname\" is mode: \"$l_mode\" (should be mode: \"$l_maxperm\" (0640) or more restrictive)")
        RESULT="FAIL"
    else
        a_output+=(" - File: \"$l_fname\" mode is compliant ($l_mode).")
    fi
done < <(find /etc/audit/ -type f \( -name "*.conf" -o -name '*.rules' \) -print0 2>/dev/null)


# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: All audit configuration files are mode: \"$l_maxperm\" or more restrictive. ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}