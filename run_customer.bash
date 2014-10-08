#!/bin/bash
home="/home/db2inst1/"
external="/media/bigdata/"
nrexp=3
delformat="del"
ixfformat="ixf"
logfile="logfiles/customerImportExport.log"
messagefile="/home/db2inst1/msg.log"
sleeptime=5
flagfile="flushnow.txt"

function inittables {
  #Drop all tables and reinsert them
  echo "Init tables"
  db2 connect to tuning
  db2 -tf drop_tables.sql
  db2 -tf init_tables.sql
  cd loaddb
  db2 -tf load.sql
  cd ..
  db2 disconnect tuning
}

function resettable {
  echo "reset CUSTOMER"
  db2 connect to tuning
  db2 "drop table customer"
  db2 "create table CUSTOMER ( customer_id int not null, username varchar(30 ), password blob, first_name varchar(30), last_name varchar(30), home_street varchar(100), home_city varchar(30), home_zip_code int, home_state varchar(30), business_street varchar(100), business_city varchar(30), business_zip_code int, business_state varchar(30), home_phone varchar(10), business_phone varchar(10), email varchar(20), language varchar(12), PRIMARY KEY (customer_id))"
  db2 disconnect tuning
}

function coldstate {
  echo "coldstate"
  db2stop
  touch $flagfile
  while [ -f $flagfile ];
  do
    sleep $sleeptime
  done
  db2start
}

function exportdb {
  echo "exportdb $1 $2"
  filename="$1customer.$2"
  echo $filename
  db2 connect to tuning
  db2 "export to $filename of $2 messages $messagefile select * from customer"
  db2 disconnect tuning
}

function importdb {
  echo "importdb $1 $2"
  filename="$1customer.$2"
  echo $filename
  db2 connect to tuning
  db2 "import from $filename of $2 method P(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17) commitcount 100000 insert into customer"
  db2 disconnect tuning
}

function loaddb {
  echo "loaddb $1 $2"
  filename="$1customer.$2"
  echo $filename
  db2 connect to tuning
  db2 "load from $filename of $2 method P(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17) insert into customer"
  db2 disconnect tuning
}

inittables

echo "*** New Cycle ***">$logfile
echo "*** New Cycle ***">$messagefile
for storage in $home $external
do
  for format in $delformat $ixfformat
  do
    for process in "exportdb" "importdb" "loaddb"
    do
      echo "** $storage - $format - $process **">>$logfile
      for (( i=1; i<=$nrexp; i++))
      do
	echo $process
	if [ "$process" == "exportdb" ];
	then
	  coldstate
	  nanotime="$(date +%s%N)"
	  exportdb $storage $format
	  nanotime="$(($(date +%s%N)-nanotime))"
	  secondstime="$((nanotime/1000000000))"
	  echo "$(date +'%D %T') Running Time:$secondstime">>$logfile
	elif [ "$process" == "importdb" ]
	then
	  resettable
	  coldstate
	  nanotime="$(date +%s%N)"
	  importdb $storage $format
	  nanotime="$(($(date +%s%N)-nanotime))"
	  secondstime="$((nanotime/1000000000))"
	  echo "$(date +'%D %T') Running Time:$secondstime">>$logfile
	else
	  resettable
	  coldstate
	  nanotime="$(date +%s%N)"
	  loaddb $storage $format
	  nanotime="$(($(date +%s%N)-nanotime))"
	  secondstime="$((nanotime/1000000000))"
	  echo "$(date +'%D %T') Running Time:$secondstime">>$logfile
	fi
      done
    done
  done
done
