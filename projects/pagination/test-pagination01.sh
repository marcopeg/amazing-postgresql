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
PAGE_SIZE=50

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
    "--page-size") set -- "$@" "-g" ;;
    *) set -- "$@" "$arg" ;;
  esac
done

# Now, process the remaining options
while getopts "c:j:t:l:r:x:y:z:g:hk" opt; do
  case $opt in
    c) CLIENTS="$OPTARG";;
    j) THREADS="$OPTARG";;
    t) TRANSACTIONS="$OPTARG";;
    l) LOG_FILE="$OPTARG";;
    r) ROWS="$OPTARG";;
    x) TOTAL_LOOPS="$OPTARG";;
    y) SLEEP="$OPTARG";;
    z) WAIT="$OPTARG";;
    g) PAGE_SIZE="$OPTARG";;
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
    --param pageSize=$PAGE_SIZE
    #  \
    # > /dev/null 2>&1
  sleep $SLEEP
done
echo ""


run_cursor_pagination() {
  NEXT_AMOUNT=0
  NEXT_ID=0
  for ((i=1; i<=TOTAL_LOOPS; i++))
  do
    echo "test page ${i}/${TOTAL_LOOPS} and sleep for $SLEEP seconds..."

    # Run cursor-union test
    ./bench.sh \
      -c $CLIENTS \
      -j $THREADS \
      -t $TRANSACTIONS \
      --file ./sql/offset-vs-cursor/$1.sql \
      --log-file $LOG_FILE \
      --serie-name "$1" \
      --param amount=$NEXT_AMOUNT \
      --param id=$NEXT_ID \
      --param pageSize=$PAGE_SIZE \
      > /dev/null 2>&1

    # Calculate next cursor to log next page
    NEXT_CURSOR=$(./query.sh -e \
      -f ./sql/offset-vs-cursor/$1-next.sql \
      -p amount=$NEXT_AMOUNT \
      -p id=$NEXT_ID \
      -p pageSize=$PAGE_SIZE
    )
    IFS="-" read -r NEXT_AMOUNT NEXT_ID <<< "$NEXT_CURSOR"

    sleep $SLEEP
  done
}

# echo "Run cursor pagination (union)"
run_cursor_pagination "cursor-union"
echo ""

echo "Run cursor pagination (or)"
run_cursor_pagination "cursor-or"