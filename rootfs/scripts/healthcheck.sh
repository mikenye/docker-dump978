#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# Exit abnormally for any error
set -eo pipefail

# Set default exit code
EXITCODE=0

# Get netstat output
NETSTAT_AN=$(netstat -an)

# Make sure dump978-fa is listening on port 30978
DUMP978_LISTENING_PORT_30978=""
REGEX_DUMP978_LISTENING_PORT_30978="^\s*tcp\s+\d+\s+\d+\s+(?>0\.0\.0\.0):30978\s+(?>0\.0\.0\.0):(?>\*)\s+LISTEN\s*$"
if echo "$NETSTAT_AN" | grep -P "$REGEX_DUMP978_LISTENING_PORT_30978" > /dev/null 2>&1; then
        DUMP978_LISTENING_PORT_30978="true"
fi
if [[ -z "$DUMP978_LISTENING_PORT_30978" ]]; then
    echo "dump978-fa not listening on port 30978, NOT OK."
    EXITCODE=1
else
    echo "dump978-fa listening on port 30978, OK."
fi

# Make sure dump978-fa is listening on port 30979
DUMP978_LISTENING_PORT_30979=""
REGEX_DUMP978_LISTENING_PORT_30979="^\s*tcp\s+\d+\s+\d+\s+(?>0\.0\.0\.0):30979\s+(?>0\.0\.0\.0):(?>\*)\s+LISTEN\s*$"
if echo "$NETSTAT_AN" | grep -P "$REGEX_DUMP978_LISTENING_PORT_30979" > /dev/null 2>&1; then
        DUMP978_LISTENING_PORT_30979="true"
fi
if [[ -z "$DUMP978_LISTENING_PORT_30979" ]]; then
    echo "dump978-fa not listening on port 30979, NOT OK."
    EXITCODE=1
else
    echo "dump978-fa listening on port 30979, OK."
fi

# Make sure socat/uat2esnt is listening on port 37981
SOCAT_LISTENING_PORT_37981=""
REGEX_SOCAT_LISTENING_PORT_37981="^\s*tcp\s+\d+\s+\d+\s+(?>0\.0\.0\.0):37981\s+(?>0\.0\.0\.0):(?>\*)\s+LISTEN\s*$"
if echo "$NETSTAT_AN" | grep -P "$REGEX_SOCAT_LISTENING_PORT_37981" > /dev/null 2>&1; then
        SOCAT_LISTENING_PORT_37981="true"
fi
if [[ -z "$SOCAT_LISTENING_PORT_37981" ]]; then
    echo "socat/uat2esnt not listening on port 37981, NOT OK."
    EXITCODE=1
else
    echo "socat/uat2esnt listening on port 37981, OK."
fi

# Make sure we're receiving messages from the SDR
for ((i = 120 ; i > -2 ; i--)); do

    # determine json filename
    if [[ "$i" -eq -1 ]]; then
        JSONFILE="/run/uat2json/aircraft.json"
    else
        JSONFILE="/run/uat2json/aircraft.json.$i"
    fi

    # make sure file exists before trying to use jq on it
    if [[ -e "$JSONFILE" ]]; then

        # get the number of messages in the file
        NUM_MSGS=$(jq .messages < "$JSONFILE")
        
        # set END_MSGS to most recent number of messages
        END_MSGS="$NUM_MSGS"

        # if we haven't yet set START_MSGS, then set it
        if [[ -z "$START_MSGS" ]]; then
            START_MSGS="$NUM_MSGS"
        fi
    fi

done
# if END_MSGS is greater than START_MSGS then we are receiving data
if [[ "$END_MSGS" -gt "$START_MSGS" ]]; then
    MSG_DIFF=$((END_MSGS - START_MSGS))
    echo "received $MSG_DIFF messages from SDR in past 2 hours, OK."
else
    echo "received 0 messages from SDR in past 2 hours, NOT OK."
    EXITCODE=1
fi

# Exit with determined exit status
exit "$EXITCODE"
