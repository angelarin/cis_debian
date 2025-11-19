#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.4.1.8"
DESCRIPTION="Ensure crontab is restricted to authorized users"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
FILE_ALLOW="/etc/cron.allow"
FILE_DENY="/etc/cron.deny"
EXPECTED_MODE=0640
EXPECTED_OWNER="root"
EXPECTED_GROUPS=("root" "crontab")

# Fungsi untuk memeriksa izin file
f_check_file() {
    local target_file=$1
    local expected_mode=$2
    local expected_owner=$3
    local expected_groups=("${@:4}")
    local check_status="PASS"

    if [ ! -e "$target_file" ]; then
        echo "MISSING" # Hanya untuk cron.deny
        return
    fi
    
    L_ACCESS_OCTAL=$(stat -c '%a' "$target_file")
    L_OWNER=$(stat -c '%U' "$target_file")
    L_GROUP=$(stat -c '%G' "$target_file")
    L_STAT=$(stat -Lc 'Access: (%a/%A) Owner: (%U) Group: (%G)' "$target_file")
    
    a_output+=(" - Status for $target_file: $L_STAT")

    # 1. Cek Izin
    if [ "$L_ACCESS_OCTAL" -le "$expected_mode" ]; then
        a_output+=(" - $target_file: Access is $L_ACCESS_OCTAL (<= $expected_mode).")
    else
        a_output2+=(" - $target_file: Access is $L_ACCESS_OCTAL (Less restrictive than $expected_mode).")
        check_status="FAIL"
    fi

    # 2. Cek Pemilik
    if [ "$L_OWNER" = "$expected_owner" ]; then
        a_output+=(" - $target_file: Owner is $L_OWNER.")
    else
        a_output2+=(" - $target_file: Owner is $L_OWNER (Should be $expected_owner).")
        check_status="FAIL"
    fi

    # 3. Cek Grup
    local group_match=0
    for g in "${expected_groups[@]}"; do
        if [ "$L_GROUP" = "$g" ]; then
            group_match=1
            break
        fi
    done
    
    if [ "$group_match" -eq 1 ]; then
        a_output+=(" - $target_file: Group is $L_GROUP (Approved).")
    else
        a_output2+=(" - $target_file: Group is $L_GROUP (Not approved: ${expected_groups[*]}).")
        check_status="FAIL"
    fi
    
    echo "$check_status"
}

# --- 1. Audit /etc/cron.allow ---
ALLOW_STATUS=$(f_check_file "$FILE_ALLOW" "$EXPECTED_MODE" "$EXPECTED_OWNER" "${EXPECTED_GROUPS[@]}")
if [ "$ALLOW_STATUS" = "MISSING" ]; then
    # Jika cron.allow tidak ada, maka semua user akan dicek terhadap cron.deny (atau dilarang default)
    a_output2+=(" - $FILE_ALLOW is missing. Access rules rely solely on $FILE_DENY.")
    RESULT="FAIL"
fi

# --- 2. Audit /etc/cron.deny ---
DENY_STATUS=$(f_check_file "$FILE_DENY" "$EXPECTED_MODE" "$EXPECTED_OWNER" "${EXPECTED_GROUPS[@]}")
if [ "$DENY_STATUS" = "MISSING" ]; then
    a_output+=(" - $FILE_DENY is missing (Default configuration where $FILE_ALLOW exists).")
fi
if [ "$DENY_STATUS" = "FAIL" ]; then
    RESULT="FAIL"
fi

# Jika cron.allow ada dan kondisinya PASS, hasilnya PASS. Jika ada kegagalan, hasilnya FAIL.
if [ "$ALLOW_STATUS" = "FAIL" ]; then
    RESULT="FAIL"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set/Info: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}