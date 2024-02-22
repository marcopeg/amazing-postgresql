#!/bin/bash

# Default file name, without extension
FILE_PATH=""
LOG_FILE=""
DOCKER_CONTAINER_NAME="pg"
DB_USER="postgres"
DB_NAME="postgres"
NUM_CLIENTS=10
NUM_THREADS=10
NUM_TRANSACTIONS=100
PARAMETERS=()
VERBOSE=false
SERIE_NAME=""


# Function to display help message
display_help() {
  echo "Usage: $0 [option...]" >&2
  echo
  echo "   -f --file FILE_PATH             Path to the file"
  echo "   -l --log-file LOG_FILE_PATH     Path to the log file"
  echo "   -d DB_NAME                      Database name"
  echo "   -u DB_USER                      Database user"
  echo "   -n DOCKER_CONTAINER_NAME        Docker container name"
  echo "   -c NUM_CLIENTS                  Number of clients"
  echo "   -j NUM_THREADS                  Number of threads"
  echo "   -t NUM_TRANSACTIONS             Number of transactions"
  echo "   -p --param PARAMETERS           Additional parameters"
  echo "   -s --serie-name SERIE_NAME      Serie name"
  echo "   -v                              Verbose mode"
  echo "   -h --help                       Display help"
  echo
  exit 1
}

# If no arguments or -h is present, display help
if [ $# -eq 0 ] || [[ "$@" == *"-h"* ]]; then
  display_help
fi

# Convert long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--help") set -- "$@" "-h" ;;
    "--verbose") set -- "$@" "-v" ;;
    "--serie-name") set -- "$@" "-s" ;;
    "--log-file") set -- "$@" "-l" ;;
    "--param") set -- "$@" "-p" ;;
    "--file") set -- "$@" "-f" ;;
    "--"*) echo "Unsupported option $arg. Use -h for help." >&2; exit 1 ;;
    *) set -- "$@" "$arg" ;;
  esac
done

# Now, process the remaining options
while getopts "f:l:d:u:n:c:j:t:p:s:vh" opt; do
  case $opt in
    f) FILE_PATH="$OPTARG";;
    l) LOG_FILE="$OPTARG";;
    d) DB_NAME="$OPTARG";;
    u) DB_USER="$OPTARG";;
    n) DOCKER_CONTAINER_NAME="$OPTARG";;
    c) NUM_CLIENTS="$OPTARG";;
    j) NUM_THREADS="$OPTARG";;
    t) NUM_TRANSACTIONS="$OPTARG";;
    p) PARAMETERS+=("$OPTARG");;
    v) VERBOSE=true;;
    h) display_help;;
    s) SERIE_NAME="$OPTARG";;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
  esac
done

# No file path provided, use default
if [[ -z "$FILE_PATH" ]]; then
  echo "Usage: $0 [options] <file-path>" >&2
  exit 1
fi

# If FILE_PATH starts with ./, remove it
if [[ $FILE_PATH == ./* ]]; then
  FILE_PATH="${FILE_PATH:2}"
fi

# Complete file path
FILE_TO_MONITOR="$(pwd)/${FILE_PATH}"

# Check if the file exists
if [ ! -f "$FILE_TO_MONITOR" ]; then
  echo "Error: \"./${FILE_PATH}\" does not exist." >&2
  exit 1
fi

# Construct the parameters string for pgbench
PARAMS_STRING=""
for param in "${PARAMETERS[@]}"; do
  PARAMS_STRING+=" -D \"$param\""
done

# echo "Running \"./${FILE_PATH}\"."
# echo ""

# Construct the docker exec command
COMMAND="docker exec -i \"$DOCKER_CONTAINER_NAME\" pgbench -U \"$DB_USER\" -c $NUM_CLIENTS -j $NUM_THREADS -t $NUM_TRANSACTIONS -f \"/sql/${FILE_PATH#*/}\" $PARAMS_STRING $DB_NAME 2>/dev/null"

if $VERBOSE; then
  # If verbose is true, run the command and print the output
  eval "$COMMAND"
else
  # If verbose is false, run the command, save the output, and extract the TPS value
  OUTPUT=$(eval "$COMMAND")
  TPS=$(echo "$OUTPUT" | grep "tps = " | awk '{print int($3)}')
  echo $TPS
fi

# If a log file is specified, append the information to it
if [[ -n "$LOG_FILE" ]]; then
  if [[ -n "$SERIE_NAME" ]]; then
    echo "$SERIE_NAME,$NUM_CLIENTS,$NUM_THREADS,$NUM_TRANSACTIONS,${PARAMETERS[*]},$TPS" >> "$LOG_FILE"
  else
    echo "$FILE_PATH,$NUM_CLIENTS,$NUM_THREADS,$NUM_TRANSACTIONS,${PARAMETERS[*]},$TPS" >> "$LOG_FILE"
  fi
fi