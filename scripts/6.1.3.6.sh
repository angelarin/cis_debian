#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.3.6"
DESCRIPTION="Ensure rsyslog is configured to send logs to a remote log host (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_include='\$IncludeConfig' a_config_files=("/etc/rsyslog.conf")

# --- FUNGSI PENGUMPULAN FILE (Sama seperti 6.1.3.5) ---
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

# --- FUNGSI AUDIT REMOTE LOGGING ---
L_REMOTE_RULES=""
L_OMFWD_RULES=""

for l_logfile in "${a_config_files[@]}"; do
    # 1. Basic format: @@<host>
    L_REMOTE_RULES+=$(grep -Hs -- "^*.*[^I][^I]*@" "$l_logfile" 2>/dev/null)
    
    # 2. Advanced format: action(type="omfwd" target="...")
    L_OMFWD_RULES+=$(grep -PHsi -- '^\s*([^#]+\s+)?action\(([^#]+\s+)?\btarget=\"?[^#"]+\"?\b' "$l_logfile" 2>/dev/null)
done

if [ -n "$L_REMOTE_RULES" ] || [ -n "$L_OMFWD_RULES" ]; then
    a_output+=(" - Remote logging mechanism detected:")
    [ -n "$L_REMOTE_RULES" ] && a_output+=("   Basic Format: ${L_REMOTE_RULES//$'\n'/ | }")
    [ -n "$L_OMFWD_RULES" ] && a_output+=("   Advanced Format: ${L_OMFWD_RULES//$'\n'/ | }")
else
    a_output2+=(" - No remote logging configuration detected. This is a potential FAIL if centralization is required by site policy.")
    RESULT="FAIL"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "FAIL" ]; then
    NOTES+="FAIL: Remote logging may be missing. ${a_output2[*]}"
else
    NOTES+="REVIEW: Remote logging rules detected. ${a_output[*]}"
    NOTES+=" | Action: REVIEW the FQDN/IP address and protocol/port against site policy."
    RESULT="REVIEW"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}