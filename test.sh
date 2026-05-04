#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.3.1.2"
DESCRIPTION="Ensure AppArmor is enabled in the bootloader configuration"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
GRUB_CONFIG="/boot/grub/grub.cfg"

# --- FUNGSI AUDIT GRUB CONFIG ---
if [ ! -f "$GRUB_CONFIG" ]; then
    a_output2+=(" - GRUB configuration file ($GRUB_CONFIG) not found.")
else
    # 1. Cek apparmor=1
    L_OUTPUT_AA1=$(grep "^\s*linux" "$GRUB_CONFIG" | grep -v "apparmor=1")
    if [ -z "$L_OUTPUT_AA1" ]; then
        a_output+=(" - All kernel lines include 'apparmor=1'.")
    else
        a_output2+=(" - Some kernel lines are missing 'apparmor=1'. Offending lines: $L_OUTPUT_AA1")
    fi

    # 2. Cek security=apparmor
    L_OUTPUT_SEC=$(grep "^\s*linux" "$GRUB_CONFIG" | grep -v "security=apparmor")
    if [ -z "$L_OUTPUT_SEC" ]; then
        a_output+=(" - All kernel lines include 'security=apparmor'.")
    else
        a_output2+=(" - Some kernel lines are missing 'security=apparmor'. Offending lines: $L_OUTPUT_SEC")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}