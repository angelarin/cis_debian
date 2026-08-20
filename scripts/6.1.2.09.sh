#!/usr/bin/env bash

CHECK_ID="6.1.2.9"
DESCRIPTION="Ensure rsyslog-gnutls is installed"

{
if dpkg-query -s rsyslog-gnutls &>/dev/null; then
    RESULT="PASS"
    NOTES="PASS: Package 'rsyslog-gnutls' is installed."
else
    RESULT="FAIL"
    NOTES="FAIL: Package 'rsyslog-gnutls' is not installed. Please install it using 'apt install rsyslog-gnutls'."
fi

echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}