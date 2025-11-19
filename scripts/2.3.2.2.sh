#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.3.2.2"
DESCRIPTION="Ensure systemd-timesyncd is enabled and running"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SERVICE="systemd-timesyncd.service"

# 1. Cek status ENABLED
L_ENABLED=$(systemctl is-enabled "$SERVICE" 2>/dev/null)
if [ "$L_ENABLED" = "enabled" ]; then
    a_output+=(" - Service '$SERVICE' is ENABLED for boot.")
else
    RESULT="FAIL"
    a_output2+=(" - Service '$SERVICE' is NOT enabled (Status: $L_ENABLED).")
fi

# 2. Cek status ACTIVE
L_ACTIVE=$(systemctl is-active "$SERVICE" 2>/dev/null)
if [ "$L_ACTIVE" = "active" ]; then
    a_output+=(" - Service '$SERVICE' is currently ACTIVE.")
else
    RESULT="FAIL"
    a_output2+=(" - Service '$SERVICE' is NOT active (Status: $L_ACTIVE).")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    # Jika ada kegagalan, ubah status RESULT
    [ "$RESULT" != "FAIL" ] && RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}