#!/bin/bash
logfile="logfiles/$1.log"
queryfile="queries/select_$1.sql"
insertfile="inserts/insert_$1.sql"
deletefile="inserts/delete_$1.sql"
readinsert="queries/select_inserted_$1.sql"
flagfile="flushnow.txt"
sleeptime=2s
nrexp=$2
echo "********************">>$logfile
echo "* $1 ">>$logfile
echo "********************">>$logfile
echo "-- COLD SELECT QUERY --">>$logfile
for (( i=1; i<=$nrexp; i++))
do
  #read -p "Flush cache on host and press [Enter]."
  touch $flagfile
  while [ -f $flagfile ];
  do
    sleep $sleeptime
  done
  db2stop
  db2start
  db2batch -a db2inst1/tuning -d tuning -f $queryfile | grep "* Total Time" >>$logfile
done

echo "-- WARM SELECT QUERY --">>$logfile
for (( i=1; i<=$nrexp; i++))
do
  db2batch -a db2inst1/tuning -d tuning -f $queryfile | grep "* Total Time" >>$logfile
done
if [ -f $insertfile ];
then
  echo "-- COLD INSERT --">>$logfile
for (( i=1; i<=$nrexp; i++))
do
  touch $flagfile
  while [ -f $flagfile ];
  do
    sleep $sleeptime
  done
  db2stop
  db2start
  db2batch -a db2inst1/tuning -d tuning -f $insertfile | grep "* Total Time" >>$logfile
  db2batch -a db2inst1/tuning -d tuning -f $deletefile
done
echo "-- WARM INSERT --">>$logfile
for (( i=1; i<=$nrexp; i++))
do
  db2batch -a db2inst1/tuning -d tuning -f $insertfile | grep "* Total Time" >>$logfile
  db2batch -a db2inst1/tuning -d tuning -f $deletefile
done
echo "-- COLD READ INSERT --">>$logfile
db2batch -a db2inst1/tuning -d tuning -f $insertfile
for (( i=1; i<=$nrexp; i++))
do
  touch $flagfile
  while [ -f $flagfile ];
  do
    sleep $sleeptime
  done
  db2stop
  db2start
  db2batch -a db2inst1/tuning -d tuning -f $readinsert | grep "* Total Time" >>$logfile
done
echo "-- WARM READ INSERT --">>$logfile
for (( i=1; i<=$nrexp; i++))
do
  db2batch -a db2inst1/tuning -d tuning -f $readinsert | grep "* Total Time" >>$logfile
done
db2batch -a db2inst1/tuning -d tuning -f $deletefile
fi
echo "* CYCLE END *">>$logfile
