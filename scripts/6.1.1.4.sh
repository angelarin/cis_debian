#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.1.4"
DESCRIPTION="Ensure only one logging system is in use"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
ACTIVE_RSYSLOG=$(systemctl is-active --quiet rsyslog && echo "y")
ACTIVE_JOURNALD=$(systemctl is-active --quiet systemd-journald && echo "y")

# --- FUNGSI AUDIT SINGLE LOGGER ---
if [ "$ACTIVE_RSYSLOG" = "y" ] && [ "$ACTIVE_JOURNALD" = "y" ]; then
    RESULT="FAIL"
    a_output2+=(" - Multiple logging systems are ACTIVE: rsyslog AND systemd-journald.")
elif [ "$ACTIVE_RSYSLOG" = "y" ]; then
    a_output+=(" - Only rsyslog is active. Follow rsyslog recommendations.")
elif [ "$ACTIVE_JOURNALD" = "y" ]; then
    a_output+=(" - Only systemd-journald is active. Follow journald recommendations.")
else
    RESULT="FAIL"
    a_output2+=(" - Unable to determine system logging status OR neither rsyslog nor systemd-journald is active.")
    a_output2+=(" - Configure only ONE system logging: rsyslog OR journald.")
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