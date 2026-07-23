#!/bin/bash

RED='\033[0;31m' #AB format echo text as red
NC='\033[0m' #AB format echo text as "no color"
BOLD_CYAN='\e[1;36m' #AB format echo text as bold cyan
BOLD='\e[1m' #AB format echo text as bold
LIME='\e[38;5;82m' #AB format echo text as bright green

run_slam=0
ssh_loc="lidar@10.42.0.1"


function print_help() { #AB This function prints the help text
    cat << 'EOF'
------------------------------------------------------------------------------------------HELP PAGE FOR install.sh------------------------------------------------------------------------------------------

install.sh - A script to set up a computer for one of Ingenium LiDAR's computer systems.
License: GPL-3.0
Version: 2.0.0 (2026-07-21)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
EOF
}


function print_version() {
    echo "$version"
    exit 0
}


function ssh_send() {
  command="$1"
  ssh "$ssh_loc" "$command"
  error_code=$?
  if [[ $error_code -eq 255 ]]; then #AB 255 usually means SSH connection failed
      echo "SSH connection failed. Are you connected to the RPi's hotspot?" >&2
      exit 255
  elif [[ $error_code -ne 0 ]]; then #AB Process inside the ssh exited with an error code
      echo 'Remote command "$command" failed with exit code $error_code' >&2
      exit $error_code
  fi
}


PARSED=$(getopt -o hvqfp:b: --long help,verbose,quiet,force,package:,branch:,version,omit-gui -n "$0" -- "$@")
eval set -- "$PARSED"


while true; do
  case "$1" in
    -h|--help) print_help; shift ;;
    -s|--SLAM) run_slam=1; shift ;;
    --ssh) ssh_loc="$2"; shift 2 ;;
    --) shift; break ;;
    *) echo "Unexpected option: $1" >&2; print_help; exit 2 ;;
  esac
done


