#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.2"
DESCRIPTION="Ensure actions as another user are always logged"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
ARCHS=("b64" "b32")
FOUND_COUNT_DISK=0
FOUND_COUNT_LOADED=0

# --- FUNGSI AUDIT ---

# On Disk Check
for arch in "${ARCHS[@]}"; do
    L_OUTPUT=$(awk -v arch="$arch" '
        /^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -F *arch='${arch}'/ && / -S *execve/ && \
        (/ -F *auid!=unset/||/ -F *auid!=-1/||/ -F *auid!=4294967295/) && \
        (/ -C *euid!=uid/||/ -C *uid!=euid/) && \
        (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)
        { print $0 }
    ' /etc/audit/rules.d/*.rules 2>/dev/null)
    
    if [ -n "$L_OUTPUT" ]; then
        a_output+=(" - Disk: Rule for arch=$arch found. Detected: ${L_OUTPUT//$'\n'/ | }")
        FOUND_COUNT_DISK=$((FOUND_COUNT_DISK + 1))
    else
        a_output2+=(" - Disk: Rule for arch=$arch (user_emulation) is MISSING.")
    fi
done

# Loaded Check (auditctl -l)
for arch in "${ARCHS[@]}"; do
    L_OUTPUT=$(auditctl -l 2>/dev/null | awk -v arch="$arch" '
        /^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -F *arch='${arch}'/ && / -S *execve/ && \
        (/ -F *auid!=unset/||/ -F *auid!=-1/||/ -F *auid!=4294967295/) && \
        (/ -C *euid!=uid/||/ -C *uid!=euid/) && \
        (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)
        { print $0 }
    ')
    
    if [ -n "$L_OUTPUT" ]; then
        a_output+=(" - Loaded: Rule for arch=$arch found. Detected: ${L_OUTPUT//$'\n'/ | }")
        FOUND_COUNT_LOADED=$((FOUND_COUNT_LOADED + 1))
    else
        a_output2+=(" - Loaded: Rule for arch=$arch (user_emulation) is MISSING.")
    fi
done


# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_COUNT_DISK" -eq 2 ] && [ "$FOUND_COUNT_LOADED" -eq 2 ]; then
    NOTES+="PASS: All 4 required rules (2 disk, 2 loaded) found. ${a_output[*]}"
elif [ "$FOUND_COUNT_DISK" -eq 2 ]; then
    RESULT="FAIL"
    NOTES+="FAIL: Disk config passed ($FOUND_COUNT_DISK/2), but loaded config failed ($FOUND_COUNT_LOADED/2). ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Disk configuration failed ($FOUND_COUNT_DISK/2). Loaded configuration status: $FOUND_COUNT_LOADED/2. ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}