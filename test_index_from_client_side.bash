#!/bin/bash
nrexp=3
logfile="logfiles/appserver.log"
flagfile="flushnow.txt"
sleeptime=2s

function testappserver {
  nc 10.0.0.10 4001 < user2.checkout
}

function inittables {
  #Drop all tables and reinsert them
  db2 connect to tuning
  db2 -tf drop_tables.sql
  db2 -tf init_tables.sql
  cd loaddb
  db2 -tf load.sql
  cd ..
  db2 disconnect tuning
}

function createindex {
  db2 connect to tuning
  db2batch -a db2inst1/tuning -d tuning -f create_index.sql
  db2 reorg table room_date index xroom_date
  db2 runstats on table hotel and indexes all;
  db2 runstats on table room_type and indexes all;
  db2 runstats on table room_date and indexes all;
  db2 runstats on table customer and indexes all;
  db2 runstats on table shopping_cart and indexes all;
  db2 disconnect tuning
}

for exp in "Baseline" "Clustered"
do
  echo "*** $exp ***">>$logfile
  for (( i=1; i<=$nrexp; i++))
  do
    inittables
    if [ $exp == "Clustered" ];
    then
      createindex
    fi
    db2stop
    touch $flagfile
    while [ -f $flagfile ];
    do
      sleep $sleeptime
    done
    db2start
    nanotime="$(date +%s%N)"
    testappserver
    nanotime="$(($(date +%s%N)-nanotime))"
    mstime="$((nanotime/1000000))"
    echo "Running Time:$mstime">>$logfile
  done
done
