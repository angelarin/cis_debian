#!/usr/bin/env bash

{
    output1=""
    output2=""
    # Di Debian, file global adalah /etc/bash.bashrc
    [ -f /etc/bash.bashrc ] && BRC="/etc/bash.bashrc" || BRC="/etc/bashrc"

    # Pola untuk mencari TMOUT <= 900
    p_ok='^\s*([^#]+\s+)?TMOUT=(900|[1-8][0-9][0-9]|[1-9][0-9]|[1-9])\b'
    # Pola untuk mencari TMOUT > 900 atau 0 (unlimited)
    p_fail='^\s*([^#]+\s+)?TMOUT=(9[0-9][1-9]|9[1-9][0-9]|0+|[1-9]\d{3,})\b'

    for f in "$BRC" /etc/profile /etc/profile.d/*.sh ; do
        if [ -f "$f" ]; then
            if grep -Pq "$p_ok" "$f" && \
               grep -Pq '^\s*([^#]+;\s*)?readonly\s+TMOUT' "$f" && \
               grep -Pq '^\s*([^#]+;\s*)?export\s+TMOUT' "$f"; then
                output1="$f"
            fi
            
            if grep -Pq "$p_fail" "$f"; then
                output2="$f"
            fi
        fi
    done

    if [ -n "$output1" ] && [ -z "$output2" ]; then
        echo -e "\nPASSED\n\nTMOUT is configured correctly in: \"$output1\"\n"
    else
        echo -e "\nFAILED"
        [ -z "$output1" ] && echo "- TMOUT is not configured, not readonly, or not exported."
        [ -n "$output2" ] && echo "- TMOUT is incorrectly configured (too long or disabled) in: $output2"
        echo ""
    fi
}