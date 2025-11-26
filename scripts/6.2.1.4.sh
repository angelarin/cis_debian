#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.1.4"
DESCRIPTION="Ensure audit_backlog_limit is sufficient (set in GRUB)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
GRUB_CONFIG="/boot/grub/grub.cfg"
TARGET_PARAM="audit_backlog_limit="

# --- FUNGSI AUDIT GRUB BACKLOG ---
if [ ! -f "$GRUB_CONFIG" ]; then
    a_output2+=(" - GRUB configuration file ($GRUB_CONFIG) not found.")
    RESULT="FAIL"
else
    # Mencari baris kernel yang TIDAK memiliki audit_backlog_limit=<angka>
    L_MISSING=$(find /boot -type f -name 'grub.cfg' -exec grep -Ph -- '^\h*linux' {} + 2>/dev/null | grep -Pv 'audit_backlog_limit=\d+\b')
    
    if [ -n "$L_MISSING" ]; then
        RESULT="FAIL"
        a_output2+=(" - Some kernel lines are missing the '$TARGET_PARAM<value>' parameter.")
        a_output2+=(" - Offending lines found in grub.cfg: ${L_MISSING//$'\n'/ | }")
    else
        a_output+=(" - All kernel lines include the '$TARGET_PARAM<value>' parameter.")
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