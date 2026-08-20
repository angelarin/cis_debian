#!/usr/bin/env bash

CHECK_ID="3.2.3"
DESCRIPTION="Ensure dccp kernel module is not available"

{
RESULT="PASS" NOTES=""
MODULE="dccp"

# 1. Periksa apakah modul sedang dimuat (loaded) di kernel
if lsmod | grep -qw "$MODULE"; then
    RESULT="FAIL"
    NOTES="FAIL: The $MODULE kernel module is currently loaded."
else
    # 2. Periksa apakah modul tersedia di sistem (menggunakan find lebih aman dari **)
    MOD_EXISTS=0
    if [ -n "$(find /lib/modules /usr/lib/modules -type d -name "$MODULE" 2>/dev/null -print -quit)" ] || modinfo "$MODULE" >/dev/null 2>&1; then
        MOD_EXISTS=1
    fi

    if [ "$MOD_EXISTS" -eq 0 ]; then
        NOTES="PASS: The $MODULE kernel module is not available on the system."
    else
        # 3. Jika modul tersedia, pastikan sudah dinonaktifkan (blacklist & install /bin/false)
        MOD_CONF=$(modprobe --showconfig 2>/dev/null | grep -P -- "\b(install|blacklist)\h+${MODULE}\b")
        
        HAS_BLACKLIST=0
        HAS_INSTALL=0
        
        if echo "$MOD_CONF" | grep -q -P "^blacklist\s+${MODULE}\b"; then HAS_BLACKLIST=1; fi
        if echo "$MOD_CONF" | grep -q -P "^install\s+${MODULE}\s+/bin/(false|true)\b"; then HAS_INSTALL=1; fi
        
        if [ "$HAS_BLACKLIST" -eq 1 ] && [ "$HAS_INSTALL" -eq 1 ]; then
            NOTES="PASS: $MODULE is available but correctly disabled (blacklisted and install set to /bin/false or true)."
        else
            RESULT="FAIL"
            NOTES="FAIL: $MODULE is available but NOT fully disabled (Blacklist: $HAS_BLACKLIST, Install: $HAS_INSTALL)."
        fi
    fi
fi

# Cetak hasil akhir
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}