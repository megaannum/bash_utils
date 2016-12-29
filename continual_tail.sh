#!/bin/bash

declare -r SCRIPT=$(basename $0)
declare -r SCRIPT_DIR=$(cd "$(dirname $0)"; pwd)
declare -r BASE_DIR=$(cd "$SCRIPT_DIR/.."; pwd)

#  
# continual_tail.sh  
#  This is an example script showing how to continually tail the
#    latest log file in a given directory.
#    It uses the "tail --pid=$pid -f ...." options that stop a 
#    tail when the pid dies.
#  Applicable when the same executable/script is run over and over
#    again and you wish to simple see that log files keep being
#    generated and each individual log file keeps being added to
#    (that is, until the process generating the log file dies).
#  

# NOTE: this must be defined prior to using this script
declare -r NAME_OF_PROCESS="my_script.sh"

# NOTE: this must be defined prior to using this script
#       this is where the $NAME_OF_PROCESS generates its log files
declare -r LOGS_DIR="/home/dragon/tmp"


function usage() {
  if [[ "$@" != "" ]]; then
    echo $@
  fi

  cat <<EOF
Usage: $SCRIPT options
  Tail the logs files.
    This script will continuosly tail the current log file generated
    in a given directory.
    When one script generating the latest file being tailed ends, 
    the script will wait for the next file and automagically start tailing it.

  Where options:"
     -h or --help 
      Print this help text
EOF
  exit 1
}

#
# parse arguments
#
while [[ $# -gt 0 && "$1" == -* ]]; do
  declare optarg=

  case "$1" in
    -*=*)
      optarg=$(echo "$1" | sed 's/[-_a-zA-Z0-9]*=//')
    ;;
    *)
      optarg=
    ;;
  esac

  case "$1" in
    -h | --help )
      usage ""
      ;;

    -* )
      usage "Unknown option \"$1\""
      ;;

  esac

  shift
done

#
# Currently supports on arguments, change if you want
#
if [[ $# -gt 0 ]]; then
  usage "Unknown argument: $@"
fi


if [[ ! -d $LOGS_DIR ]]; then
  echo "ERROR: logs directory does not exists: $LOGS_DIR"
  exit 1
fi

#
# get the process id and job_id of the latest running script
#
function getPidAndJobDir() {
  ps axuwww | grep $NAME_OF_PROCESS | head -1 | awk '{print $2 " " $NF}'
}

#
# tail the log file if found
#
function runOnce() {
  local -r pid_jobdir="$( getPidAndJobDir )"
  if [[ "$pid_jobdir" != "" ]]; then
    # get pid
    local -r pid=$( echo $pid_jobdir | cut -d ' ' -f1 )

    # NOTE: this must be defined for this to work
    # get unique identifier associated with log file
    local -r unique_id=""

    # NOTE: this must be defined for this to work
    # generate log file name from unique_id
    local -r log_file_name=""

    # echo "pid=$pid"
    # echo "unique_id=$unique_id"
    # echo "log_file_name=$log_file_name"
    echo "TAIL_LOG:$pid:$unique_id:$log_file_name"

    # Note that the following list files new than 15 seconds
    # find . -newermt '-15 seconds' -type f -print

    if [[ "$log_file_name" == "" ]]; then
      echo "FATAL: must define log_file_name"
      exit 1
    fi

    tail --pid=$pid -f -c +0 $log_file_name
  fi
}

#
# tail the log file if found then try again
#
function run() {
  while [[ true ]]; do
    runOnce
    # Note: if script execution times are less than 4 second 
    # then the script's log file might be missed
    sleep 4
  done
}

cd $LOGS_DIR
run

