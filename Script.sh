#!/bin/bash
# Designed to be run inside the user environment to create a sparse bundle image which contains parity and checksums
# Band size is 256MB
# variables
# check if AC adapter is connected before running script if not exit
if [[ $(pmset -g ps | head -1) =~ "AC Power" ]]; then
  echo "Charger is connected, proceeding with backup, do not disconnect charger!" 
  else echo "Please connect charger, then execute the backup script again! Exiting" && exit 1
fi
echo ""
echo "Stage 1 - Retrieve Username - Starting"
# retrieving username
CONSOLEUSER="$(stat -f %Su /dev/console)" || { echo "`date +"%x %R%p"`: Failed to get username correctly. Exiting"; exit 1; }
echo "Complete - `date +"%x %R%p"`"
echo ""
echo "Stage 2 - Previous Image Check - Starting"
# stash and eject previous image if exists
if [ -d "/Volumes/$CONSOLEUSER.sparsebundle" ]; then
  /usr/bin/hdiutil eject "/Volumes/$CONSOLEUSER.sparsebundle" || { echo "`date +"%x %R%p"`: Failed to unmount previous image. Try again"; exit 1; }
  sleep 10
fi
if [ -d "/tmp/$CONSOLEUSER.sparsebundle" ]; then
  mv "/tmp/$CONSOLEUSER.sparsebundle" "/tmp/$CONSOLEUSER.previous`date +%s`.sparsebundle" || { echo "`date +"%x %R%p"`: Failed to rename previous image. Exiting"; exit 1; }
fi
echo "Complete - `date +"%x %R%p"`"
echo ""
echo "Stage 3 - Create Image - Starting... Perfect time to grab a brew!"
# create sparse image - updated with -quiet
/usr/bin/hdiutil create -o -quiet "/tmp/$CONSOLEUSER.sparsebundle" -srcfolder "/Users/$CONSOLEUSER/" -layout SPUD -imagekey sparse-band-size=514288 -size 512g -fs HFS+J -format UDSB -volname "$CONSOLEUSER.sparsebundle" -attach  || { echo "`date +"%x %R%p"`: Failed to create image. Exiting"; exit 1; }
echo "Complete - `date +"%x %R%p"`"
echo ""
echo "Stage 4 - Image Clean - Starting"
#Remove things that do not need to be backed up
if [ -d "/Volumes/$CONSOLEUSER.sparsebundle" ]; then
  if [ -d "/Volumes/$CONSOLEUSER.sparsebundle/.Trash" ]; then
    rm -rf "/Volumes/$CONSOLEUSER.sparsebundle/.Trash"
  fi
  if [ -d "/Volumes/$CONSOLEUSER.sparsebundle/Library/Caches" ]; then
    rm -rf "/Volumes/$CONSOLEUSER.sparsebundle/Library/Caches"
  fi
else
  echo "`date +"%x %R%p"`: Image failed to mount"
  exit 1
fi
echo "Complete - `date +"%x %R%p"`"
echo ""
echo "Stage 5 - Image Compact - Starting"
# compact free space - added -quiet to both commands
/usr/bin/hdiutil eject -quiet "/Volumes/$CONSOLEUSER.sparsebundle" && sleep 10 && /usr/bin/hdiutil compact -quiet "/tmp/$CONSOLEUSER.sparsebundle" || { echo "`date +"%x %R%p"`: Disk failure. Please try again..."; exit 1; }
echo "Complete - `date +"%x %R%p"`"
echo ""
echo "Finishing..."
# notify of completion
/usr/bin/open "/tmp" && echo -ne '\007' && echo -ne '\007' && echo -ne '\007'
echo "`date +"%x %R%p"` Completed image /tmp/$CONSOLEUSER.sparsebundle is ready to be copied to IT Team folder > Employees > Ex-Employee > [name]"
