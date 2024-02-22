#!/bin/bash

is_numeric() {
  if [[ $1 =~ ^[0-9]+$ ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# Default file name, without extension
FILE_PATH=""
DOCKER_CONTAINER_NAME="pg"
DB_USER="postgres"
DB_NAME="postgres"
PARAMETERS=()
VERBOSE=false
DRY_RUN=false
EXTRACT=false


# Function to display help message
display_help() {
  echo "Description: This script allows you to run parametric queries compatible with the pgbench parameters notation."
  echo "Usage: $0 -f file.sql -p limit=10 -p page=3 [...options]"
  echo
  echo "   -f --file FILE_PATH             Path to the file"
  echo "   -d DB_NAME                      Database name"
  echo "   -u DB_USER                      Database user"
  echo "   -n DOCKER_CONTAINER_NAME        Docker container name"
  echo "   -p --param PARAMETERS           Additional parameters"
  echo "   -v --verbose                    Verbose mode"
  echo "   -e --extract                    Extract returning value"
  echo "   -r --dry-run                    Composes and prints out the query"
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
    "--param") set -- "$@" "-p" ;;
    "--file") set -- "$@" "-f" ;;
    "--extract") set -- "$@" "-e" ;;
    "--dry-run") set -- "$@" "-r" ;;
    "--"*) echo "Unsupported option $arg. Use -h for help." >&2; exit 1 ;;
    *) set -- "$@" "$arg" ;;
  esac
done

# Now, process the remaining options
while getopts "f:d:u:n:p:vhre" opt; do
  case $opt in
    f) FILE_PATH="$OPTARG";;
    d) DB_NAME="$OPTARG";;
    u) DB_USER="$OPTARG";;
    n) DOCKER_CONTAINER_NAME="$OPTARG";;
    p) PARAMETERS+=("$OPTARG");;
    v) VERBOSE=true;;
    r) DRY_RUN=true;;
    e) EXTRACT=true;;
    h) display_help;;
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

if [[ $VERBOSE == true ]]; then
  echo "Running:"
  echo "${FILE_PATH}"
  echo ""
fi


# Build the query out of the input parameters
QUERY=""
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
  echo "Query:"
  echo "$QUERY"
  echo ""
fi

# Construct the command
if [[ $DRY_RUN == false ]]; then
  escaped_query=$(echo "$QUERY" | sed "s/'/'\\\\''/g")
  COMMAND="docker exec -i $DOCKER_CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c '$escaped_query'"

  if [[ $EXTRACT == false ]]; then
    eval "$COMMAND"
  else
    RESULT=$(eval "$COMMAND")
    echo $(echo "$RESULT" | awk 'NR==3 {print $1}')
  fi
fi