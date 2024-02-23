#!/bin/bash


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

# Check if the input file exists
if [ ! -f "$1" ]; then
  echo "Input file does not exist"
  exit 1
fi

# Store the input file path
FILE_PATH="$1"
shift # Remove the first argument so only additional arguments remain

# Complete file path
FILE_TO_MONITOR="$(pwd)/${FILE_PATH}"

echo "Watching \"${FILE_PATH}\" for changes."
echo "Ctrl+C to stop."
echo ""

# Function to execute the script with any additional arguments
execute_script() {
  bash "$FILE_TO_MONITOR" "$@"
}

# Initial execution
execute_script "$@"

# Variables to prevent immediate re-execution
LAST_EXECUTION_TIME=0
EXECUTION_DELAY=1 # Seconds

# Monitor the file for modifications
fswatch -0 "$FILE_TO_MONITOR" | while IFS= read -r -d "" event; do
  CURRENT_TIME=$(date +%s)
  if (( CURRENT_TIME - LAST_EXECUTION_TIME > EXECUTION_DELAY )); then
    clear
    echo "[$(date "+%H:%M:%S")] File \"${FILE_PATH}\" has changed. Executing..."
    execute_script "$@"
    LAST_EXECUTION_TIME=$CURRENT_TIME
  fi
done