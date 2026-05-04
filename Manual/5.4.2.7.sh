#!/usr/bin/env bash

{
    # 1. Mengambil daftar shell valid (selain nologin) dari /etc/shells
    l_valid_shells="^($(awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"

    # 2. Mengambil batas minimal UID untuk user biasa (biasanya 1000)
    l_uid_min="$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"

    # 3. Menjalankan pengecekan pada /etc/passwd
    awk -v pat="$l_valid_shells" -v uid_min="$l_uid_min" -F: \
    '($1!~/^(root|halt|sync|shutdown|nfsnobody)$/ && ($3 < uid_min || $3 == 65534) && $(NF) ~ pat) \
    {print "Service account: \"" $1 "\" has a valid shell: " $7}' /etc/passwd
}