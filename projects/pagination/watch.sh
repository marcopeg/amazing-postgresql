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
while getopts "d:u:c:" opt; do
  case $opt in
    d) DB_NAME="$OPTARG";;
    u) DB_USER="$OPTARG";;
    c) DOCKER_CONTAINER_NAME="$OPTARG";;
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

# Ensure inotifywait is installed
if ! command -v fswatch &> /dev/null; then
  echo "WARINING: Please install inotify-tools."
  echo ""
  echo "\$> brew install fswatch"
  echo ""
  echo "Press ENTER to run the installation command, or ANY KEY to cancel."
  
  # Capture user input
  IFS= read -r -n1 -s input
  case "$input" in
    '') # ENTER
      echo "Installing..."
      brew install fswatch
      ;;
    *)
      echo "Installation canceled."
      exit 1
      ;;
  esac
fi

echo "Watching \"./${FILE_PATH}\"."
echo "Ctrl+C to stop."
echo ""

# Monitor the file for modifications
fswatch -0 "$FILE_TO_MONITOR" | while IFS= read -r -d "" event; do
  echo "[$(date "+%H:%M:%S")] File \"${FILE_PATH}\" has changed!"
  docker exec -i "$DOCKER_CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f "/b/$(basename "$FILE_PATH")"
done
