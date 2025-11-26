#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.3.5"
DESCRIPTION="Ensure rsyslog logging is configured (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_include='\$IncludeConfig' a_config_files=("/etc/rsyslog.conf")

# --- FUNGSI PENGUMPULAN FILE ---
# Logika untuk mencari file include $IncludeConfig dan menambahkannya ke a_config_files
while IFS= read -r l_file; do
    l_conf_loc="$(awk '$1~/^\s*'"$l_include"'$/ {print $2}' "$(tr -d '# ' <<< "$l_file")" | tail -n 1)"
    [ -n "$l_conf_loc" ] && break
done < <("$l_analyze_cmd" cat-config "${a_config_files[@]}" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

if [ -d "$l_conf_loc" ]; then
    l_dir="$l_conf_loc" l_ext="*"
elif grep -Psq '\/\*\.([^#/\n\r]+)?\h*$' <<< "$l_conf_loc" || [ -f "$(readlink -f "$l_conf_loc")" ]; then
    l_dir="$(dirname "$l_conf_loc")" l_ext="$(basename "$l_conf_loc")"
fi

while read -r -d $'\0' l_file_name; do
    [ -f "$(readlink -f "$l_file_name")" ] && a_config_files+=("$(readlink -f "$l_file_name")")
done < <(find -L "$l_dir" -type f -name "$l_ext" -print0 2>/dev/null)

# --- FUNGSI AUDIT LOGGING RULES ---
L_LOG_RULES=""
for l_logfile in "${a_config_files[@]}"; do
    L_FILE_OUTPUT=$(grep -PHs -- '^\h*[^#\n\r\/:]+\/var\/log\/.*$' "$l_logfile" 2>/dev/null)
    if [ -n "$L_FILE_OUTPUT" ]; then
        L_LOG_RULES+="${L_FILE_OUTPUT//$'\n'/ | }"
    fi
done

if [ -n "$L_LOG_RULES" ]; then
    a_output+=(" - Rsyslog logging rules detected: $L_LOG_RULES")
else
    a_output2+=(" - No rsyslog local logging rules detected (expected rules targeting /var/log/).")
    RESULT="FAIL"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "FAIL" ]; then
    NOTES+="FAIL: No local logging rules found. ${a_output2[*]}"
else
    NOTES+="REVIEW: Local logging rules detected. ${a_output[*]}"
    NOTES+=" | Action: REVIEW the detected rules (facility, priority, destination) against local site policy."
    RESULT="REVIEW"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}