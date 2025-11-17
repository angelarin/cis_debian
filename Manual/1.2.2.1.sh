#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.2.2.1"
DESCRIPTION="Ensure updates, patches, and additional security software are installed (Manual Review Required)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""

# 1. Jalankan apt update
L_UPDATE_OUTPUT=$(apt update 2>&1)
L_UPDATE_EXIT_CODE=$?

if [ $L_UPDATE_EXIT_CODE -ne 0 ]; then
    a_output2+=("APT update failed (Exit Code: $L_UPDATE_EXIT_CODE). Check repository access/health.")
else
    a_output+=("APT update succeeded.")
fi

# 2. Jalankan apt -s upgrade (Simulasi Upgrade)
L_UPGRADE_OUTPUT=$(apt -s upgrade 2>&1)

# Mencari indikasi adanya paket yang tertunda untuk di-upgrade
PENDING_UPGRADES=$(echo "$L_UPGRADE_OUTPUT" | grep -i -E 'upgraded, newly installed, to remove and [0-9]+ not upgraded\.')
UPGRADE_COUNT=$(echo "$L_UPGRADE_OUTPUT" | grep -i -E '([0-9]+) upgraded' | awk '{print $1}')

if [[ "$UPGRADE_COUNT" -eq 0 && "$PENDING_UPGRADES" =~ "0 not upgraded" ]]; then
    a_output+=("System appears to be up to date (0 packages pending upgrade).")
    RESULT="PASS"
elif [ -n "$UPGRADE_COUNT" ]; then
    a_output2+=("There are pending updates/patches. $UPGRADE_COUNT packages are listed for upgrade simulation.")
    a_output+=("Simulated upgrade list: $(echo "$L_UPGRADE_OUTPUT" | grep -E '^Inst' | head -n 5)...")
    RESULT="FAIL" # Ada paket yang tertunda
else
    a_output2+=("Could not determine pending update status accurately.")
    RESULT="REVIEW"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -gt 0 ]; then
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
else
    NOTES+="PASS: ${a_output[*]}"
fi

NOTES+=" | Action: REVIEW the update status and ensure security policies regarding patch installation are met."

# Ganti karakter enter/newline/spasi ganda dengan satu spasi untuk output satu baris
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}