#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.7.4"
DESCRIPTION="Ensure GDM screen locks when the user is idle"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# --- FUNGSI AUDIT SCREEN LOCK DELAYS ---

# 1. Cek lock-delay (<= 5 detik)
L_LOCK_DELAY_RAW=$(gsettings get org.gnome.desktop.screensaver lock-delay 2>/dev/null)
L_LOCK_DELAY=$(echo "$L_LOCK_DELAY_RAW" | grep -oP '\d+')
L_MAX_LOCK_DELAY=5

if [ -z "$L_LOCK_DELAY" ]; then
    a_output2+=(" - lock-delay value is missing or unreadable.")
    RESULT="FAIL"
elif [ "$L_LOCK_DELAY" -le "$L_MAX_LOCK_DELAY" ]; then
    a_output+=(" - lock-delay ($L_LOCK_DELAY s) is correctly set to ${L_MAX_LOCK_DELAY}s or less.")
else
    a_output2+=(" - lock-delay ($L_LOCK_DELAY s) is greater than ${L_MAX_LOCK_DELAY}s. (Raw: $L_LOCK_DELAY_RAW)")
    RESULT="FAIL"
fi

# 2. Cek idle-delay (<= 900 detik / 15 menit)
L_IDLE_DELAY_RAW=$(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null)
L_IDLE_DELAY=$(echo "$L_IDLE_DELAY_RAW" | grep -oP '\d+')
L_MAX_IDLE_DELAY=900

if [ -z "$L_IDLE_DELAY" ]; then
    a_output2+=(" - idle-delay value is missing or unreadable.")
    RESULT="FAIL"
elif [ "$L_IDLE_DELAY" -eq 0 ]; then
    a_output2+=(" - idle-delay is set to 0, which disables locking.")
    RESULT="FAIL"
elif [ "$L_IDLE_DELAY" -le "$L_MAX_IDLE_DELAY" ]; then
    a_output+=(" - idle-delay ($L_IDLE_DELAY s) is correctly set to ${L_MAX_IDLE_DELAY}s or less.")
else
    a_output2+=(" - idle-delay ($L_IDLE_DELAY s) is greater than ${L_MAX_IDLE_DELAY}s. (Raw: $L_IDLE_DELAY_RAW)")
    RESULT="FAIL"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES+="INFO: Values must be verified against local site policy. "

if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}