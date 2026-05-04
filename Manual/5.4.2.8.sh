#!/usr/bin/env bash

{
    # 1. Membuat pola shell yang valid untuk login
    l_valid_shells="^($(awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"

    # 2. Loop melalui user yang shell-nya BUKAN shell login (nologin/false)
    while IFS= read -r l_user; do
        # Cek status password. Jika bukan "L" (Locked), maka laporkan.
        passwd -S "$l_user" | awk '$2 !~ /^L/ {print "Account: \"" $1 "\" does not have a valid login shell and is not locked"}'
    done < <(awk -v pat="$l_valid_shells" -F: '($1 != "root" && $(NF) !~ pat) {print $1}' /etc/passwd)
}