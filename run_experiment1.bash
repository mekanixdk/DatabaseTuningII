#!/bin/bash
#Initialize experiments
#Drop all tables and reinsert them
db2 connect to tuning
db2 -tf drop_tables.sql
db2 -tf init_tables.sql
cd loaddb
db2 -tf load.sql
cd ..
db2 disconnect tuning
#How manynrexp=3
repeats ofeach experiments
#Baseline
for exp in "xroom_date" "xhotel1" "xhotel2" "xroom_type" "xroom_date" "xcustomer" 
do
  logfile="logfiles/$exp.log"
  echo $logfile
  echo "************">>$logfile
  echo "* BASELINE *">>$logfile
  echo "************">>$logfile
  bash common.bash $exp $nrexp
done
#Create index
logfile="logfiles/index.log"
db2 connect to tuning
echo "create index"
db2batch -a db2inst1/tuning -d tuning -f create_index.sql >>$logfile
echo "running runstats"
db2 reorg table room_date index xroom_date
db2 runstats on table hotel and indexes all;
db2 runstats on table room_type and indexes all;
db2 runstats on table room_date and indexes all;
db2 runstats on table customer and indexes all;
db2 runstats on table shopping_cart and indexes all;
db2 disconnect tuning
db2stop
db2start

#Run experiments
for exp in "xroom_date" "xhotel1" "xhotel2" "xroom_type" "xroom_date" "xcustomer" #"xshopping_cart"
do
  logfile="logfiles/$exp.log"
  echo "**************">>$logfile
  echo "* EXPERIMENT *">>$logfile
  echo "**************">>$logfile
  bash common.bash $exp $nrexp
done

