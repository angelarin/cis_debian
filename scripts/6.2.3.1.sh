#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.1"
DESCRIPTION="Ensure changes to system administration scope (sudoers) is collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILES=("/etc/sudoers" "/etc/sudoers.d")

# Aturan yang diharapkan (On Disk)
EXPECTED_RULES=(
    "-w /etc/sudoers -p wa -k scope"
    "-w /etc/sudoers.d -p wa -k scope"
)
EXPECTED_COUNT=2
FOUND_COUNT=0

# --- FUNGSI AUDIT SUDOERS ---
for target in "${TARGET_FILES[@]}"; do
    # Buat regex yang kompleks untuk memverifikasi rule dengan path, perm, dan key yang benar
    # Note: Karena awk/grep tidak dapat menjamin urutan -p dan -k, kita cek keberadaan masing-masing komponen.
    L_OUTPUT=$(awk -v target="$target" '
        /^ *-w/ && $2==target && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)
        { print $0 }
    ' /etc/audit/rules.d/*.rules 2>/dev/null)
    
    if [ -n "$L_OUTPUT" ]; then
        a_output+=(" - Rule for '$target' found on disk. Detected: ${L_OUTPUT//$'\n'/ | }")
        FOUND_COUNT=$((FOUND_COUNT + 1))
    else
        a_output2+=(" - Rule for '$target' (expected: -w $target -p wa -k scope) is MISSING on disk.")
    fi
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_COUNT" -eq "$EXPECTED_COUNT" ]; then
    NOTES+="PASS: All $EXPECTED_COUNT required rules are configured on disk. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: $FOUND_COUNT/$EXPECTED_COUNT rules found. Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}