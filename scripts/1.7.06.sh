#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.7.6"
DESCRIPTION="Ensure GDM automatic mounting of removable media is disabled"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# --- FUNGSI AUDIT GDM AUTOMOUNT ---
SETTINGS=(
    "org.gnome.desktop.media-handling automount"
    "org.gnome.desktop.media-handling automount-open"
)

for setting in "${SETTINGS[@]}"; do
    L_VALUE=$(gsettings get "$setting" 2>/dev/null)
    if [ "$L_VALUE" = "false" ]; then
        a_output+=(" - $setting is correctly set to false.")
    else
        RESULT="FAIL"
        a_output2+=(" - $setting is set to $L_VALUE (should be false).")
    fi
done

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