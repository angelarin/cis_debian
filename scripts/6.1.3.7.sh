#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.3.7"
DESCRIPTION="Ensure rsyslog is not configured to receive logs from a remote client"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
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

# --- FUNGSI AUDIT PENERIMAAN LOGS ---
VIOLATION_FOUND=0
for l_logfile in "${a_config_files[@]}"; do
    # Cek Advanced format (module(load="imtcp") atau input(type="imtcp"))
    L_FAIL_ADVANCED=$(grep -Psi -- '^\h*module\(load=\"?imtcp\"?\)' "$l_logfile" 2>/dev/null)
    [ -n "$L_FAIL_ADVANCED" ] && a_output2+=("- Entry to accept incoming logs (imtcp module load) found in: \"$l_logfile\". Line: ${L_FAIL_ADVANCED//$'\n'/ | }") && VIOLATION_FOUND=1
    
    L_FAIL_INPUT=$(grep -Psi -- '^\h*input\(type=\"?imtcp\"?\b' "$l_logfile" 2>/dev/null)
    [ -n "$L_FAIL_INPUT" ] && a_output2+=("- Entry to accept incoming logs (imtcp input type) found in: \"$l_logfile\". Line: ${L_FAIL_INPUT//$'\n'/ | }") && VIOLATION_FOUND=1
    
    # Cek Obsolete format (module(load="imudp") atau input(type="imudp") juga perlu diperhatikan, meskipun audit hanya menyebutkan imtcp)
    L_FAIL_INPUT_UDP=$(grep -Psi -- '^\h*module\(load=\"?imudp\"?\)' "$l_logfile" 2>/dev/null)
    [ -n "$L_FAIL_INPUT_UDP" ] && a_output2+=("- Entry to accept incoming logs (imudp module load) found in: \"$l_logfile\". Line: ${L_FAIL_INPUT_UDP//$'\n'/ | }")
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$VIOLATION_FOUND" -eq 0 ]; then
    a_output+=(" - No rsyslog configurations found that enable receiving remote logs (imtcp/imudp).")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: System is configured to accept remote logs (imtcp/imudp). This is a security risk if the system is not a log server. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}