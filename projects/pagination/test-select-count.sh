#!/bin/bash

SLEEP=3
CHUNCK_SIZE=100000
TOTAL_LOOPS=10

# Parse command line arguments
while getopts "c:t:s:" opt; do
  case $opt in
    c)
      CHUNCK_SIZE=$OPTARG
      ;;
    t)
      TOTAL_LOOPS=$OPTARG
      ;;
    s)
      SLEEP=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

# Clear logs
rm -rf ./log.csv

#
# No Index
#
echo "Reset schema"
./bench.sh -c 1 -j 1 -t 1 -f ./sql/select-count/schema.sql 1>/dev/null


for ((i=1; i<=TOTAL_LOOPS; i++))
do
  echo "Seed $(printf "%'d" $CHUNCK_SIZE) records ... to $(printf "%'d" $((CHUNCK_SIZE * i))) records"
  ./bench.sh -c 1 -j 1 -t 1 -f ./sql/select-count/seed.sql -p amount=$CHUNCK_SIZE 1>/dev/null

  echo "Sleep ${SLEEP}s"
  sleep $SLEEP

  ./bench.sh -c 1 -j 1 -t 1 -l log.csv -f ./sql/select-count/select-no-index.sql -p amount=$CHUNCK_SIZE 
done



#
# With Index
#
echo "Reset schema"
./bench.sh -c 1 -j 1 -t 1 -f ./sql/select-count/schema.sql 1>/dev/null
./bench.sh -c 1 -j 1 -t 1 -f ./sql/select-count/index.sql 1>/dev/null


for ((i=1; i<=TOTAL_LOOPS; i++))
do
  echo "Seed $(printf "%'d" $CHUNCK_SIZE) records ... to $(printf "%'d" $((CHUNCK_SIZE * i))) records"
  ./bench.sh -c 1 -j 1 -t 1 -f ./sql/select-count/seed.sql -p amount=$CHUNCK_SIZE 1>/dev/null

  echo "Sleep ${SLEEP}s"
  sleep $SLEEP

  ./bench.sh -c 1 -j 1 -t 1 -l log.csv -f ./sql/select-count/select-with-index.sql -p amount=$CHUNCK_SIZE 
done