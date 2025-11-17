#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.3.1"
DESCRIPTION="Ensure separate partition exists for /home"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT /home MOUNT STATUS ---
L_OUTPUT=$(findmnt -kn /home)

if [ -n "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=("/home is currently mounted. Findmnt output: $L_OUTPUT")
    NOTES+="PASS: ${a_output[*]}"
else
    # Meskipun /home mungkin tidak pada partisi terpisah, status "not mounted"
    # biasanya dianggap fail dalam konteks hardening jika /home digunakan.
    RESULT="FAIL"
    a_output2+=("/home is NOT mounted.")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
# --------------------------------------------------------------------------
}