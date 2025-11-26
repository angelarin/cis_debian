#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.4.9"
DESCRIPTION="Ensure audit tools owner is configured (owner: root)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
EXPECTED_OWNER="root"
a_audit_tools=("/sbin/auditctl" "/sbin/aureport" "/sbin/ausearch" "/sbin/autrace" "/sbin/auditd" "/sbin/augenrules")
VIOLATIONS_FOUND=0

# --- FUNGSI AUDIT OWNER TOOLS ---
L_OUTPUT=$(stat -Lc "%n %U" "${a_audit_tools[@]}" 2>/dev/null | awk '$2 != "root" {print}')

if [ -n "$L_OUTPUT" ]; then
    RESULT="FAIL"
    a_output2+=(" - Detected audit tool(s) NOT owned by '$EXPECTED_OWNER'. Violations: ${L_OUTPUT//$'\n'/ | }")
else
    a_output+=(" - All audit tools are owned by '$EXPECTED_OWNER'.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}