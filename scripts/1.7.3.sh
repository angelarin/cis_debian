#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.7.3"
DESCRIPTION="Ensure GDM disable-user-list option is enabled"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
SETTING="org.gnome.login-screen disable-user-list"

# --- FUNGSI AUDIT GDM SETTINGS ---
L_VALUE=$(gsettings get $SETTING 2>/dev/null)

if [ "$L_VALUE" = "true" ]; then
    RESULT="PASS"
    a_output+=(" - $SETTING is correctly set to true.")
else
    RESULT="FAIL"
    a_output2+=(" - $SETTING is set to $L_VALUE (should be true).")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}