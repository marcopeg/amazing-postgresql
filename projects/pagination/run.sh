#!/bin/bash

# Default file name, without extension
FILE_PATH=""
DOCKER_CONTAINER_NAME="pg"
DB_USER="postgres"
DB_NAME="postgres"

# First, extract the file path which is not an option (not starting with '-')
for arg in "$@"; do
  if [[ "$arg" != -* ]]; then
    FILE_PATH="$arg"
    break # Stop at the first non-option argument
  fi
done

# Remove the file path from the arguments list
args=()
for arg in "$@"; do
  if [[ "$arg" != "$FILE_PATH" ]]; then
    args+=("$arg")
  fi
done
set -- "${args[@]}"

# Now, process the remaining options
while getopts "d:u:n:" opt; do
  case $opt in
    d) DB_NAME="$OPTARG";;
    u) DB_USER="$OPTARG";;
    n) DOCKER_CONTAINER_NAME="$OPTARG";;
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

echo "Running \"./${FILE_PATH}\"."
echo ""
docker exec -i "$DOCKER_CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f "/sql/${FILE_PATH#*/}"
