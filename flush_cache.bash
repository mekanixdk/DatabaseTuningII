#!/bin/bash
flagfile="flushnow.txt"
endloop=0
sleeptime=2s
while [ $endloop == 0 ];
  do
    sleep $sleeptime
    if [ -f $flagfile ];
    then
      sync
      echo 3 > /proc/sys/vm/drop_caches
      echo "remove flagfile"
      rm $flagfile
  fi
done
