#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.2.1.4"
DESCRIPTION="Ensure systemd-journal-remote service is not in use"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SERVICES=("systemd-journal-remote.socket" "systemd-journal-remote.service")
VIOLATION_FOUND=0

# 1. Cek status ENABLED
L_ENABLED_OUTPUT=$(systemctl is-enabled "${SERVICES[@]}" 2>/dev/null | grep -P -- '^enabled')
if [ -n "$L_ENABLED_OUTPUT" ]; then
    a_output2+=(" - Detected ENABLED component(s): ${L_ENABLED_OUTPUT//$'\n'/ | }")
    VIOLATION_FOUND=1
else
    a_output+=(" - Services/sockets are NOT enabled.")
fi

# 2. Cek status ACTIVE
L_ACTIVE_OUTPUT=$(systemctl is-active "${SERVICES[@]}" 2>/dev/null | grep -P -- '^active')
if [ -n "$L_ACTIVE_OUTPUT" ]; then
    a_output2+=(" - Detected ACTIVE component(s): ${L_ACTIVE_OUTPUT//$'\n'/ | }")
    VIOLATION_FOUND=1
else
    a_output+=(" - Services/sockets are NOT active.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$VIOLATION_FOUND" -eq 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    a_output+=(" - NOTE: These services must be disabled unless the system is designated as a central log receiver.")
    NOTES+="FAIL: Detected active or enabled remote log listener components. ${a_output2[*]} | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}