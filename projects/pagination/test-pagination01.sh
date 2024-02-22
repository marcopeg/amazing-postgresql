#!/bin/bash

ROWS=1000000
CLIENTS=10
THREADS=10
TRANSACTIONS=10
LOG_FILE="log.csv"
TOTAL_LOOPS=10
WAIT=5
SLEEP=1
KEEP_DATA=0

# Help function
function show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help           Show help"
  echo "  -r, --rows           Number of rows"
  echo "  -c, --clients        Number of clients"
  echo "  -j, --threads        Number of threads"
  echo "  -t, --transactions   Number of transactions"
  echo "  -l, --log-file       Log file name"
  echo "  -k, --keep-data      Skip schema reset"
  echo "      --wait           Rest time after data seeding"
  echo "      --sleet          Rest time after a test"
  exit 0
}

# If no arguments or -h is present, display help
if [ $# -eq 0 ] || [[ "$@" == *"-h"* ]]; then
  show_help
fi

# Convert long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--help") set -- "$@" "-h" ;;
    "--rows") set -- "$@" "-r" ;;
    "--log-file") set -- "$@" "-l" ;;
    "--loops") set -- "$@" "-x" ;;
    "--sleep") set -- "$@" "-y" ;;
    "--wait") set -- "$@" "-z" ;;
    "--keep-data") set -- "$@" "-k" ;;
    *) set -- "$@" "$arg" ;;
  esac
done

# Now, process the remaining options
while getopts "c:j:t:l:r:x:y:z:hk" opt; do
  case $opt in
    c) CLIENTS="$OPTARG";;
    j) THREADS="$OPTARG";;
    t) TRANSACTIONS="$OPTARG";;
    l) LOG_FILE="$OPTARG";;
    r) ROWS="$OPTARG";;
    x) TOTAL_LOOPS="$OPTARG";;
    y) SLEEP="$OPTARG";;
    z) WAIT="$OPTARG";;
    k) KEEP_DATA=1;;
    h) display_help;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
  esac
done


# Reset log file
touch $LOG_FILE
: > $LOG_FILE


# Reset the database
if [ "$KEEP_DATA" = "0" ]; then
  echo "Reset schema with $ROWS rows..."
  ./run.sh sql/offset-vs-cursor/_schema.sql > /dev/null 2>&1
  ./bench.sh -c 1 -j 1 -t 1 -f ./sql/offset-vs-cursor/_seed.sql -p rows=$ROWS > /dev/null 2>&1
  ./run.sh sql/offset-vs-cursor/_index.sql > /dev/null 2>&1

  echo "Sleeping for $WAIT seconds..."
  sleep $WAIT
fi
echo ""

# Run offset test
echo "> Running offset test..."
for ((i=1; i<=TOTAL_LOOPS; i++))
do
  echo "test page ${i}/${TOTAL_LOOPS} and sleep for $SLEEP seconds..."
  ./bench.sh \
    -c $CLIENTS \
    -j $THREADS \
    -t $TRANSACTIONS \
    --file ./sql/offset-vs-cursor/offset.sql \
    --log-file $LOG_FILE \
    --serie-name "offset" \
    --param page=$i \
    > /dev/null 2>&1
  sleep $SLEEP
done
echo ""


# Run cursor-or test
# echo "> Running cursor-or test..."
# for ((i=1; i<=TOTAL_LOOPS; i++))
# do
#   echo "test page ${i}/${TOTAL_LOOPS} and sleep for $SLEEP seconds..."
#   ./bench.sh \
#     -c $CLIENTS \
#     -j $THREADS \
#     -t $TRANSACTIONS \
#     --file ./sql/offset-vs-cursor/cursor-or.sql \
#     --log-file $LOG_FILE \
#     --serie-name "cursor-or" \
#     --param amount=$(((i * 10) - 10)) \
#     > /dev/null 2>&1
#   sleep $SLEEP
# done
# echo ""

# Run cursor-union test
echo "> Running cursor-union test..."
for ((i=1; i<=TOTAL_LOOPS; i++))
do
  echo "test page ${i}/${TOTAL_LOOPS} and sleep for $SLEEP seconds..."
  ./bench.sh \
    -c $CLIENTS \
    -j $THREADS \
    -t $TRANSACTIONS \
    --file ./sql/offset-vs-cursor/cursor-union.sql \
    --log-file $LOG_FILE \
    --serie-name "cursor-union" \
    --param amount=$(((i * 10) - 10)) \
    > /dev/null 2>&1
  sleep $SLEEP
done