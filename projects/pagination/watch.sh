#!/bin/bash

# Default file name, without extension
FILE_NAME="default"
DOCKER_CONTAINER_NAME="pg"
DB_USER="postgres"
DB_NAME="postgres"

# Parse command-line options
while getopts "f:d:u:c:" opt; do
  case $opt in
    f) FILE_NAME="$OPTARG";;
    d) DB_NAME="$OPTARG";;
    u) DB_USER="$OPTARG";;
    c) DOCKER_CONTAINER_NAME="$OPTARG";;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
  esac
done

# Complete file path
FILE_TO_MONITOR="$(pwd)/${FILE_NAME}"

# Check if the file exists
if [ ! -f "$FILE_TO_MONITOR" ]; then
  echo "Error: \"./${FILE_NAME}\" does not exist." >&2
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

echo "Watching \"./${FILE_NAME}\"."
echo "Ctrl+C to stop."
echo ""

# Monitor the file for modifications
fswatch -0 "$FILE_TO_MONITOR" | while IFS= read -r -d "" event; do
  echo "[$(date "+%H:%M:%S")] File \"${FILE_NAME}\" has changed!"
  docker exec -i "$DOCKER_CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -f "/b/$(basename "$FILE_NAME")"
done
