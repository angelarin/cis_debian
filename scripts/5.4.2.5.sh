#!/usr/bin/env bash

CHECK_ID="5.4.2.5"
DESCRIPTION="Ensure root path integrity"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
l_output2=""
l_pmask="0022"
l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )" # Max perms 755
EXPECTED_OWNER="root"

# Dapatkan PATH root
l_root_path="$(sudo -Hiu root env 2>/dev/null | grep '^PATH' | cut -d= -f2)"

if [ -z "$l_root_path" ]; then
    a_output2+=(" - WARNING: Could not determine root PATH variable.")
    RESULT="FAIL"
else
    a_output+=(" - Root PATH: $l_root_path")
    unset a_path_loc && IFS=":" read -ra a_path_loc <<< "$l_root_path"

    grep -q "::" <<< "$l_root_path" && l_output2="$l_output2 | root path contains a empty directory (::)"
    grep -Pq ":\h*$" <<< "$l_root_path" && l_output2="$l_output2 | root path contains a trailing (:)"
    grep -Pq '(\h+|:)\.(:|\h*$)' <<< "$l_root_path" && l_output2="$l_output2 | root path contains current working directory (.)"

    for l_path in "${a_path_loc[@]}"; do
        if [ -d "$l_path" ]; then
            while read -r l_fmode l_fown; do
                if [ "$l_fown" != "$EXPECTED_OWNER" ]; then
                    l_output2="$l_output2 | Directory: \"$l_path\" is owned by: \"$l_fown\" should be owned by \"$EXPECTED_OWNER\""
                fi
                if [ $(( $l_fmode & $l_pmask )) -gt 0 ]; then
                    l_output2="$l_output2 | Directory: \"$l_path\" is mode: \"$l_fmode\" and should be mode: \"$l_maxperm\" or more restrictive"
                fi
            done <<< "$(stat -Lc '%#a %U' "$l_path")"
        elif [ -n "$l_path" ]; then
            l_output2="$l_output2 | \"$l_path\" is not a directory"
        fi
    done
fi

if [ -n "$l_output2" ]; then
    RESULT="FAIL"
    l_output2="${l_output2# \| }"
    NOTES+="FAIL: * Reasons for audit failure * : $l_output2"
else
    NOTES+="PASS: Root path is correctly configured."
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}