#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.3.8"
DESCRIPTION="Ensure logrotate is configured (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_config_file="/etc/logrotate.conf"
L_INCLUDE_DIR=""
L_OUTPUT=""

# 1. Dapatkan direktori include
l_include="$(awk '$1~/^\s*include$/{print$2}' "$l_config_file" 2>/dev/null | tail -n 1)"
[ -d "$l_include" ] && L_INCLUDE_DIR="$l_include/*"

# 2. Gabungkan konfigurasi
L_OUTPUT=$("$l_analyze_cmd" cat-config "$l_config_file" "$L_INCLUDE_DIR" 2>/dev/null)

if [ -n "$L_OUTPUT" ]; then
    a_output+=(" - Effective logrotate configuration retrieved. Review below for compliance.")
    
    # Batasi output log untuk NOTES agar tidak terlalu panjang
    L_OUTPUT_TRUNCATED=$(echo "$L_OUTPUT" | head -n 30)
    a_output+=(" - Configuration Sample (First 30 lines): ${L_OUTPUT_TRUNCATED//$'\n'/ | }")
else
    a_output2+=(" - Failed to retrieve logrotate configuration using systemd-analyze.")
    RESULT="FAIL"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "FAIL" ]; then
    NOTES+="FAIL: Configuration files inaccessible. ${a_output2[*]}"
else
    NOTES+="REVIEW: Effective logrotate configuration collected. ${a_output[*]}"
    NOTES+=" | Action: REVIEW the rotation frequency, size limits, and retention policy against local site policy."
    RESULT="REVIEW"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}