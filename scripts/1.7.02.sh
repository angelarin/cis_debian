#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.7.2"
DESCRIPTION="Ensure GDM login banner is configured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# --- FUNGSI AUDIT GDM SETTINGS ---
SETTINGS=(
    "org.gnome.login-screen banner-message-enable"
    "org.gnome.login-screen banner-message-text"
)

# 1. Cek banner-message-enable
L_ENABLE=$(gsettings get ${SETTINGS[0]} 2>/dev/null)
if [ "$L_ENABLE" = "true" ]; then
    a_output+=(" - banner-message-enable is correctly set to true.")
else
    RESULT="FAIL"
    a_output2+=(" - banner-message-enable is set to $L_ENABLE (should be true).")
fi

# 2. Cek banner-message-text
L_TEXT=$(gsettings get ${SETTINGS[1]} 2>/dev/null)
if [ -n "$L_TEXT" ] && [ "$L_TEXT" != "''" ] && [ "$L_TEXT" != '""' ]; then
    a_output+=(" - banner-message-text is set. (Value: $L_TEXT)")
else
    RESULT="FAIL"
    a_output2+=(" - banner-message-text is NOT set or is empty.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES+="INFO: Value must be verified against site policy. "

if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}