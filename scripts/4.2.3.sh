#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.2.3"
DESCRIPTION="Ensure ufw service is enabled and active"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SERVICE="ufw.service"
DAEMON_NAME="ufw"

# 1. Cek status ENABLED
L_ENABLED=$(systemctl is-enabled "$SERVICE" 2>/dev/null)
if [ "$L_ENABLED" = "enabled" ]; then
    a_output+=(" - UFW service is ENABLED for boot (Status: $L_ENABLED).")
else
    a_output2+=(" - UFW service is NOT enabled (Status: $L_ENABLED).")
    RESULT="FAIL"
fi

# 2. Cek status ACTIVE (via systemctl)
L_ACTIVE_SYSTEMCTL=$(systemctl is-active "$DAEMON_NAME" 2>/dev/null)
if [ "$L_ACTIVE_SYSTEMCTL" = "active" ]; then
    a_output+=(" - UFW daemon is currently ACTIVE (via systemctl).")
else
    a_output2+=(" - UFW daemon is NOT active (systemctl status: $L_ACTIVE_SYSTEMCTL).")
    RESULT="FAIL"
fi

# 3. Cek status ACTIVE (via ufw status)
L_UFW_STATUS=$(ufw status 2>/dev/null | grep 'Status:')
if echo "$L_UFW_STATUS" | grep -q 'active'; then
    a_output+=(" - UFW status confirms ACTIVE. ($L_UFW_STATUS)")
else
    a_output2+=(" - UFW status is NOT active. ($L_UFW_STATUS)")
    RESULT="FAIL"
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