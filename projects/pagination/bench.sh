#!/bin/bash

# Default file name, without extension
FILE_PATH=""
DOCKER_CONTAINER_NAME="pg"
DB_USER="postgres"
DB_NAME="postgres"
NUM_CLIENTS=10
NUM_THREADS=10
NUM_TRANSACTIONS=100
PARAMETERS=()

# First, extract the file path which is not an option (not starting with '-')
# for arg in "$@"; do
#   if [[ "$arg" != -* ]]; then
#     FILE_PATH="$arg"
#     break # Stop at the first non-option argument
#   fi
# done

# Remove the file path from the arguments list
# args=()
# for arg in "$@"; do
#   if [[ "$arg" != "$FILE_PATH" ]]; then
#     args+=("$arg")
#   fi
# done
# set -- "${args[@]}"

# Now, process the remaining options
while getopts "f:d:u:n:c:j:t:p:" opt; do
  case $opt in
    f) FILE_PATH="$OPTARG";;
    d) DB_NAME="$OPTARG";;
    u) DB_USER="$OPTARG";;
    n) DOCKER_CONTAINER_NAME="$OPTARG";;
    c) NUM_CLIENTS="$OPTARG";;
    j) NUM_THREADS="$OPTARG";;
    t) NUM_TRANSACTIONS="$OPTARG";;
    p) PARAMETERS+=("$OPTARG");;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
  esac
done

# No file path provided, use default
if [[ -z "$FILE_PATH" ]]; then
  echo "Usage: $0 [options] <file-path>" >&2
  exit 1
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

echo "Running \"./${FILE_PATH}\"."
echo ""

# Construct the docker exec command
COMMAND="docker exec -i \"$DOCKER_CONTAINER_NAME\" pgbench -U \"$DB_USER\" -c $NUM_CLIENTS -j $NUM_THREADS -t $NUM_TRANSACTIONS -f \"/sql/${FILE_PATH#*/}\" $PARAMS_STRING $DB_NAME 2>/dev/null"

# Print the command
#echo "$COMMAND"

# Run the command
eval "$COMMAND"