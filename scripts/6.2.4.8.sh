#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.4.8"
DESCRIPTION="Ensure audit tools mode is configured (mode <= 0755)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
l_perm_mask="0022" # Mask 0022 = Other Write, Group Write
l_maxperm="$( printf '%o' $(( 0777 & ~$l_perm_mask )) )" # 0755
a_audit_tools=("/sbin/auditctl" "/sbin/aureport" "/sbin/ausearch" "/sbin/autrace" "/sbin/auditd" "/sbin/augenrules")

# --- FUNGSI AUDIT MODE TOOLS ---
for l_audit_tool in "${a_audit_tools[@]}"; do
    if [ -x "$l_audit_tool" ]; then
        l_mode="$(stat -Lc '%#a' "$l_audit_tool")"
        # Cek apakah mode saat ini lebih longgar dari 0755
        if [ $(( "$l_mode" & "$l_perm_mask" )) -gt 0 ]; then
            a_output2+=(" - Audit tool \"$l_audit_tool\" is mode: \"$l_mode\" and should be mode: \"$l_maxperm\" (0755) or more restrictive")
            RESULT="FAIL"
        else
            a_output+=(" - Audit tool \"$l_audit_tool\" is correctly configured to mode: \"$l_mode\" (<= 0755).")
        fi
    else
        # Jika tool tidak ada/tidak dapat dieksekusi, anggap sebagai FAIL karena harus ada
        a_output2+=(" - Audit tool \"$l_audit_tool\" is missing or not executable.")
        RESULT="FAIL"
    fi
done

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