#!/bin/bash

help() {
  echo "Description: This script allows you to run parametric queries compatible with the pgbench parameters notation."
  echo "Usage: $0 -f file.sql -p limit=10 -p page=3 [...options]"
  echo
  echo "   -h --help                       Display this help"
  echo "   -f --file                       Path to the sql file (relative to the script)"
  echo "   -p --param                      SQL parameters (e.g. -p count=10 -p page=3 -> LIMIT=:count)"
  echo "   -e --extract                    Extract returning value"
  echo "   -w --watch                      Re-run the query on change"
  echo "   -v --verbose                    Verbose mode"
  echo "   -d --dry-run                    Composes and prints out the query"
  echo "   --db-name                       Database name (default: postgres)"
  echo "   --db-user                       Database user (default: postgres)"
  echo "   --container-name                Docker container name (default: pg)"
  echo
  exit 1
}

is_numeric() {
  if [[ $1 =~ ^[0-9]+$ ]]; then
    echo "true"
  else
    echo "false"
  fi
}

FILE_PATH=""         # Default file path (local to the script)
DK_NAME="pg"         # Default Docker container name
DB_USER="postgres"   # Default database user
DB_NAME="postgres"   # Default database name
PARAMETERS=()        # Array to store parameters (-p count=10 -p page=3)
VERBOSE=false        # Verbose mode
DRY_RUN=false        # Dry run mode, prints out the query
EXTRACT=false        # Extract returning value (first column of the first row)
WATCH=false          # Watch file for changes and re-run the query

# If no arguments or -h is present, display help
if [ $# -eq 0 ] || [[ "$@" == *"-h"* ]]; then
  help
fi

# Process long-named options
while (( "$#" )); do
  case "$1" in
    "--container-name")
      DK_NAME="$2"
      shift 2
      ;;
    "--db-name")
      DB_NAME="$2"
      shift 2
      ;;
    "--db-user")
      DB_USER="$2"
      shift 2
      ;;
    "--help")
      set -- "$@" "-h"
      shift
      ;;
    "--verbose")
      set -- "$@" "-v"
      shift
      ;;
    "--watch")
      set -- "$@" "-w"
      shift
      ;;
    "--param")
      set -- "$@" "-p"
      shift
      ;;
    "--file")
      set -- "$@" "-f"
      shift
      ;;
    "--extract")
      set -- "$@" "-e"
      shift
      ;;
    "--dry-run")
      set -- "$@" "-d"
      shift
      ;;
    "--"*)
      echo "Unsupported option $1. Use -h for help." >&2
      exit 1
      ;;
    *)
      # If it's not a known option, just append it to the new arguments list
      NEW_ARGS+=("$1")
      shift
      ;;
  esac
done

# Set "$@" to NEW_ARGS, containing only the unprocessed arguments
set -- "${NEW_ARGS[@]}"

# Process single character options
while getopts "f:p:vhdew" opt; do
  case $opt in
    f) FILE_PATH="$OPTARG";;
    p) PARAMETERS+=("$OPTARG");;
    v) VERBOSE=true;;
    d) DRY_RUN=true;;
    e) EXTRACT=true;;
    w) WATCH=true;;
    h) help;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
  esac
done

# No file path provided, use default
if [[ -z "$FILE_PATH" ]]; then
  echo "ERROR: File path is required!" >&2
  echo "       Try this way:" >&2
  echo "" >&2
  echo "       $0 -f <file-path> [options]" >&2
  echo "" >&2
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
  echo "ERROR: \"./${FILE_PATH}\" does not exist." >&2
  echo "" >&2
  exit 1
fi

if [[ $VERBOSE == true ]]; then
  echo "👉 RUNNING:"
  echo "${FILE_PATH}"
  echo ""
fi

# Build the query out of the input parameters
# (this will substitute placeholders like ":count" with parameters like "-p count=10")
QUERY=""

PARAMS_STRING=""
for param in "${PARAMETERS[@]}"; do
  PARAMS_STRING+=" -D \"$param\""
done

for param in "${PARAMETERS[@]}"; do
  IFS="=" read -r key value <<< "$param"

  # Dynamically inject wrappers for strings
  if [[ $(is_numeric "$value") == "true" ]]; then
    QUERY+="-e 's/:$key/$value/g' "
  else
    escaped_value=$(echo "$value" | sed "s/'/'\\\\''/g")
    QUERY+="-e 's/:$key/'\''$escaped_value'\''/g' "
  fi
done
QUERY=$(cat $FILE_TO_MONITOR | tr '\n' ' ' | eval sed "$QUERY")

if [[ $VERBOSE == true || $DRY_RUN == true ]]; then
  echo "👉 QUERY:"
  echo "$QUERY"
  echo ""
fi

# Construct the command
if [[ $DRY_RUN == false ]]; then
  escaped_query=$(echo "$QUERY" | sed "s/'/'\\\\''/g")
  COMMAND="docker exec -i $DK_NAME psql -U $DB_USER -d $DB_NAME -c '$escaped_query'"

  if [[ $WATCH == true ]]; then

    # Ensure fswatch is installed
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

    if [[ $VERBOSE == true || $DRY_RUN == true ]]; then
      echo "👉 WATCHING \"./${FILE_PATH}\"."
      echo "(Ctrl+C to stop)"
      echo ""
    fi

    # First execution
    eval "$COMMAND"

    # Variables to prevent immediate re-execution
    LAST_EXECUTION_TIME=0
    EXECUTION_DELAY=1 # Seconds

    fswatch -0 "$FILE_TO_MONITOR" | while IFS= read -r -d "" event; do
      CURRENT_TIME=$(date +%s)
      if (( CURRENT_TIME - LAST_EXECUTION_TIME > EXECUTION_DELAY )); then
        clear
        echo "👉 [$(date "+%H:%M:%S")] File \"${FILE_PATH}\" has changed"
        echo ""
        eval "$COMMAND"
        LAST_EXECUTION_TIME=$CURRENT_TIME
      fi
    done
    exit 0
  fi

  if [[ $EXTRACT == false ]]; then
    eval "$COMMAND"
  else
    RESULT=$(eval "$COMMAND")
    echo $(echo "$RESULT" | awk 'NR==3 {print $1}')
  fi
fi