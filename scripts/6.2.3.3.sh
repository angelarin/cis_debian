#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.3"
DESCRIPTION="Ensure events that modify the sudo log file are collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
FOUND_COUNT_DISK=0
FOUND_COUNT_LOADED=0

# Dapatkan path logfile sudo dan escape karakter '/' untuk regex
SUDO_LOG_FILE=$(grep -r logfile /etc/sudoers /etc/sudoers.d/* 2>/dev/null | sed -e 's/.*logfile=//;s/,?.*//' -e 's/"//g' -e 's|/|\\/|g' | head -n 1)

if [ -z "$SUDO_LOG_FILE" ]; then
    a_output+=(" - WARNING: Sudo logfile is NOT configured. Audit skipped (Refer to 5.2.3).")
    RESULT="PASS" # Status Pass, tapi dengan warning/note
else
    a_output+=(" - Sudo logfile path detected: ${SUDO_LOG_FILE//\\/}.")
    
    # On Disk Check
    L_OUTPUT=$(awk -v logfile="$SUDO_LOG_FILE" '
        /^ *-w/ && index($0, logfile) && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)
        { print $0 }
    ' /etc/audit/rules.d/*.rules 2>/dev/null)
    
    if [ -n "$L_OUTPUT" ]; then
        a_output+=(" - Disk: Rule for sudo logfile found. Detected: ${L_OUTPUT//$'\n'/ | }")
        FOUND_COUNT_DISK=1
    else
        a_output2+=(" - Disk: Rule (-w ${SUDO_LOG_FILE//\\/} -p wa -k sudo_log_file) is MISSING.")
    fi
    
    # Loaded Check (auditctl -l)
    L_OUTPUT_LOADED=$(auditctl -l 2>/dev/null | awk -v logfile="$SUDO_LOG_FILE" '
        /^ *-w/ && index($0, logfile) && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)
        { print $0 }
    ')
    
    if [ -n "$L_OUTPUT_LOADED" ]; then
        a_output+=(" - Loaded: Rule for sudo logfile found. Detected: ${L_OUTPUT_LOADED//$'\n'/ | }")
        FOUND_COUNT_LOADED=1
    else
        a_output2+=(" - Loaded: Rule (-w ${SUDO_LOG_FILE//\\/} -p wa -k sudo_log_file) is MISSING.")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_COUNT_DISK" -eq 1 ] && [ "$FOUND_COUNT_LOADED" -eq 1 ]; then
    NOTES+="PASS: Sudo logfile is audited correctly (Disk and Loaded). ${a_output[*]}"
elif [ -z "$SUDO_LOG_FILE" ]; then
    NOTES+="PASS: Audit skipped because Sudo logfile is not configured. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Sudo logfile auditing failed (Disk: $FOUND_COUNT_DISK/1, Loaded: $FOUND_COUNT_LOADED/1). ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}