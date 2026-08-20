#!/usr/bin/env bash

CHECK_ID="6.2.3.37"
DESCRIPTION="Ensure the running and on disk configuration is the same"

{
RESULT="PASS" NOTES=""

# Mengeksekusi augenrules --check dan menangkap output (termasuk error)
# tr digunakan untuk menghapus newline agar format log tetap dalam satu baris
OUTPUT=$(augenrules --check 2>&1 | tr '\n' ' ' | sed 's/  */ /g' | xargs)

# Mengecek apakah output mengandung kata "No change"
if echo "$OUTPUT" | grep -iq "No change"; then
    NOTES="PASS: The running and on disk configuration is the same (Output: $OUTPUT)."
else
    RESULT="FAIL"
    NOTES="FAIL: Drift detected between running and on-disk audit configuration. (Output: $OUTPUT). Run 'augenrules --load' to fix."
fi

# Cetak hasil akhir
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}