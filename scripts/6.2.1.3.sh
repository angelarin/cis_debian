#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.1.3"
DESCRIPTION="Ensure auditing for processes that start prior to auditd is enabled (audit=1 in GRUB)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
GRUB_CONFIG="/boot/grub/grub.cfg"
TARGET_PARAM="audit=1"

# --- FUNGSI AUDIT GRUB ---
if [ ! -f "$GRUB_CONFIG" ]; then
    a_output2+=(" - GRUB configuration file ($GRUB_CONFIG) not found.")
    RESULT="FAIL"
else
    # Mencari baris kernel yang TIDAK memiliki audit=1
    L_MISSING=$(find /boot -type f -name 'grub.cfg' -exec grep -Ph -- '^\h*linux' {} + 2>/dev/null | grep -v "$TARGET_PARAM")
    
    if [ -n "$L_MISSING" ]; then
        RESULT="FAIL"
        a_output2+=(" - Some kernel lines are missing the '$TARGET_PARAM' parameter.")
        a_output2+=(" - Offending lines found in grub.cfg: ${L_MISSING//$'\n'/ | }")
    else
        a_output+=(" - All kernel lines include the '$TARGET_PARAM' parameter.")
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