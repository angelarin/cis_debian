#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.3.1.1"
DESCRIPTION="Ensure a single time synchronization daemon is in use"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
l_timesyncd="n" l_chrony="n" l_out_tsd="" l_out_chrony=""

service_not_enabled_chk()
{
l_out2=""
if systemctl is-enabled "$l_service_name" 2>/dev/null | grep -q 'enabled'; then
    l_out2="$l_out2 - Daemon: \"$l_service_name\" is enabled on the system"
fi
if systemctl is-active "$l_service_name" 2>/dev/null | grep -q '^active'; then
    l_out2="$l_out2 - Daemon: \"$l_service_name\" is active on the system"
fi
}

# 1. Check systemd-timesyncd daemon
l_service_name="systemd-timesyncd.service"
service_not_enabled_chk
if [ -n "$l_out2" ]; then
    l_timesyncd="y"
    l_out_tsd="$l_out2"
else
    l_timesyncd="n"
    l_out_tsd="- Daemon: \"$l_service_name\" is not enabled and not active on the system"
fi

# 2. Check chrony
l_service_name="chrony.service"
l_out2="" # Reset l_out2
service_not_enabled_chk
if [ -n "$l_out2" ]; then
    l_chrony="y"
    l_out_chrony="$l_out2"
else
    l_chrony="n"
    l_out_chrony="- Daemon: \"$l_service_name\" is not enabled and not active on the system"
fi

# 3. Assess combined status
l_status="$l_timesyncd$l_chrony"
case "$l_status" in
yy)
    RESULT="FAIL"
    a_output2+=(" - More than one time sync daemon is in use on the system.")
    a_output2+=("$l_out_tsd $l_out_chrony")
    ;;
nn)
    RESULT="FAIL"
    a_output2+=(" - No time sync daemon is in use on the system.")
    a_output2+=("$l_out_tsd $l_out_chrony")
    ;;
yn|ny)
    RESULT="PASS"
    a_output+=(" - Only one time sync daemon is in use on the system.")
    a_output+=("$l_out_tsd $l_out_chrony")
    ;;
*)
    RESULT="FAIL"
    a_output2+=(" - Unable to determine time sync daemon(s) status.")
    ;;
esac

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