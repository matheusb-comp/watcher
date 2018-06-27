#!/bin/bash

# Export the log name, so the watcher script can use it
export WATCHER_LOG="/var/log/watcher.log"
# Directory where the error files will be stored
export ERROR_FOLDER="/root/error"
# Directory where the voters snaphot files will be stored
export SUCCESS_FOLDER="/root/success"

echo "checking if atd is running..."
systemctl is-active atd
if [ "$?" -ne 0 ] ; then
  echo "Daemon atd not running! Starting..."
  service atd start
  if [ "$?" -ne 0 ] ; then
    echo "ERROR starting service atd" 1>&2
    exit 1
  fi
fi

echo "creating $WATCHER_LOG..."
touch "$WATCHER_LOG"

echo "setting the watcher execution to now..."
echo "./watcherWrapper.sh $@ >> $WATCHER_LOG 2>&1" | at now

echo "tail the log file..."
tail -f "$WATCHER_LOG"
