#!/bin/bash

# This is a script that wraps the call to watcher (Golang executable that
# listens for the inflation and gets the snapshot of voters balances and data).
#
# This script will be called once a week by 'atd' (the 'at' command daemon),
# and after succesfull execution, the files produced by 'watcher'
# (error or voters) are timestamped and saved in a different folder.
# Also, this script registers it's next run with the 'at' command.
#
# On error, an email will be sent, and the script must be manually re-scheduled
# TODO: FIX: MAILTO is not being notified
#MAILTO="destination@example.com"

# Directory where this script is being executed
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NAME=$( basename "${BASH_SOURCE[0]}" )

# Timestamp format for the file names (error.json and voters.json)
FILE_FMT="+%Y-%m-%d-%H-%M-%S"
# Timestamp format for the 'at' command
AT_FMT="+%Y%m%d%H00"
# Time to wait for the next run of this script
AT_DELTA="+ 1 week - 5 hours"

# TODO: Remove - Variables used only for testing
# AT_FMT="+%Y%m%d%H%M"
# AT_DELTA="+ 4 minutes - 2 minutes"

echo "getting database password (secret)..."
source /run/secrets/$1

# Execute the watcher binary, save the Result Code and the timestamp
# Parameters are passed if the environment variable is DEFINED AND NOT EMPTY
# More info: http://mywiki.wooledge.org/BashFAQ/073#Portability
echo "executing watcher..."
/go/bin/watcher \
  ${POOL_ADDRESS:+-pool $POOL_ADDRESS} \
  ${DONATION_KEY:+-key $DONATION_KEY} \
  ${HORIZON_URL:+-horizon $HORIZON_URL} \
  ${POSTGRES_DB:+-db $POSTGRES_DB} \
  ${POSTGRES_HOST:+-host $POSTGRES_HOST} \
  ${POSTGRES_PORT:+-port $POSTGRES_PORT} \
  ${POSTGRES_USER:+-user $POSTGRES_USER} \
  ${POSTGRES_PASSWORD:+-pass $POSTGRES_PASSWORD}
RC=$?
FILE_DATE=$(date $FILE_FMT)
AT_DATE=$(date -d "$AT_DELTA" $AT_FMT)

echo "checking result..."
# If error, make a copy of the error file, notify MAILTO, and exit with status 1
if [ "$RC" -ne 0 ] ; then
  # The file may not exist (but the error message is still sent to STDERR)
  if [ -f error.json ] ; then
    # Make sure the folder exists before moving the file
    mkdir -p "$ERROR_FOLDER"
    mv error.json "$ERROR_FOLDER/$FILE_DATE-error.json"
  fi
  # TODO: Notify MAILTO
  echo "ERROR executing watcher. Cancelling next run..." 1>&2
  exit 1
fi

# With a successful execution, backup the voters file and re-schedule
if [ -f voters.json ] ; then
  # Make sure the folder exists before moving the file
  mkdir -p "$SUCCESS_FOLDER"
  mv voters.json "$SUCCESS_FOLDER/$FILE_DATE-voters.json"
fi

# Queue the next execution (pass along the parameters received)
echo "$DIR/$NAME $@ >> $WATCHER_LOG 2>&1" | at -t "$AT_DATE"
if [ "$?" -ne 0 ] ; then
  echo "ERROR setting the next execution with 'at' for $DIR/$0"
fi
