#!/bin/bash

RED='\033[0;31m' #AB format echo text as red
NC='\033[0m' #AB format echo text as "no color"
BOLD_CYAN='\e[1;36m' #AB format echo text as bold cyan
BOLD='\e[1m' #AB format echo text as bold
LIME='\e[38;5;82m' #AB format echo text as bright green

run_slam=0
ssh_loc="lidar@10.42.0.1"


function parse_args() {
  
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

}


function print_help() {
    cat << 'EOF'
----------------------------HELP PAGE FOR grabproc.sh----------------------------

grabproc.sh - A script to automatically copy data files from an RPi to a main computer and (optionally) SLAM them. 
License: GPL-3.0
Version: 2.0.0 (2026-07-21)

---------------------------------------------------------------------------------
EOF
}


function ssh_send() {
  local cmd="$1"               #AB Get parameter passed to the function. "commannd" is apparently a Bash builtin
  local func_name="${cmd%% *}" #AB Extract just the function name (before first space) for typeset
  local output
  output=$(ssh "$ssh_loc" "$(typeset -f "$func_name"); $cmd") #AB Define the function remotely via typeset, then call it with its full args
  local error_code=$? #AB get the error code from the SSH on the previous line
  if [[ $error_code -eq 255 ]]; then #AB 255 usually means SSH connection failed
      echo "SSH connection failed. Are you connected to the RPi's hotspot?" >&2
      exit 255
  elif [[ $error_code -ne 0 ]]; then #AB Process inside the ssh exited with an error code
      echo "Remote command \"$cmd\" failed with exit code $error_code" >&2
      exit $error_code
  fi
  echo "$output" #AB Send the output of the ssh right back
}


function get_Documents_Data_TLDs() {

  computer_name=$1 #AB must be either "main" or "rpi"
  cwd=$(pwd)
  cd $HOME/Documents/Data #AB This is default filesystem, so we can assume it exists

  shopt -s nullglob #AB Set *s to not interpret literally if ~/Documents/Data is empty

  dirs=(*/) #AB Get a list of all directories in current location (~/Documents/Data)
  data_dirs=() #AB Make an empty list. It will contain only directories matching the pattern "YYYY-MM-DD/"

  for dir in "${dirs[@]}"; do                                 #AB Loop through all the directories in the dirs array
      dir="${dir%/}"                                          #AB Strip the trailing slash
      if [[ "$dir" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then   #AB Big nasty RegExp. Basically, it says "if directory is of the pattern ####-##-## where #s are numbers and - is a literal -"
          data_dirs+=("$dir")
      fi
  done

  output_file="${computer_name}_extant_data_directories_$(date "+%F_%H:%M").txt"
  touch $output_file #AB Create an output file
  #AB Append each directory name from data_dirs to the output file, each on its own line
  for d in "${data_dirs[@]}"; do
      echo "$d" >> $output_file 
  done

  shopt -u nullglob #AB Set *s to interpret normally in future

  cd $cwd #AB Return to where the program was at the start of the function
  echo "$output_file"
}


function compare_directory_list_files() {

    #AB Set up variables
    local rpi_list_file="$1"
    local main_list_file="$2"
    local output_file="RPi_unique_data_files_$(date "+%F_%H:%M").txt"

    #AB Read the two files containing filtered lists of directories into arrays
    readarray -t rpi_list < "$rpi_list_file"
    readarray -t main_list < "$main_list_file"

    #AB Create an empty associative array (ie a hashmap)
    declare -A in_main_list

    #AB Associate each hashed directory name from main_list with the value "1"
    for filename in "${main_list[@]}"; do
        in_array2["$filename"]=1
    done

    # --- Compute the difference: items in array1 but NOT in array2 ------------
    difference=()

    #AB Loop through all the dirnames in rpi_list
    for filename in "${rpi_list[@]}"; do
        #AB Check the filename against the hashmap we computed earlier. If it exists in that hashmap, return the value of it in that hashmap (which is always 1). 
        #   1 is "an integer" (in German a "Zahlen"), so the "-z" flag will return true. Otherwise the string will be empty and this will evaluate to false.
        if [[ -z "${in_main_list[$filename]:-}" ]]; then 
            difference+=("$filename")                       #AB TL;DR: Add the filenames that match to the difference array
        fi
    done

    #AB printf with a %s\n format, given an array, prints one element per line. ">" redirects to the output file (forcefully, so it would overwrite, but all these files have unique timestamped names anyways)
    printf "%s\n" "${difference[@]}" > "$output_file"

    #AB Send the name of the output file back out
    echo "$output_file"
}


function zip_specified_directories() {
  local directories_to_zip_file=$1
  local dirs_to_zip # Array
  readarray -t dirs_to_zip < "$directories_to_zip_file"
  cwd=$(pwd)

  cd ~/Documents/Data
  #AB Loop through all the directories in the file passed to the function and zip them all
  for filename in "${rpi_list[@]}"; do
      zip "${filename}.zip" "$filename"
  done

  cd $cwd
}


function main(){

  #AB Declare local variables
  local local_dir_list_file
  local remote_dir_list_file
  local difference_file
  cwd=$(pwd)

  #AB Copy the appropriate files over from the RPi (remote) to the main (local) device.
  parse_args                                                                    #AB Parse script input
  remote_dir_list_file=$(ssh_send "get_Documents_Data_TLDs 'rpi'")              #AB Make a list of directories in remote://~/Documents/Data/ that follow the YYYY-MM-DD pattern. This variable stores the filename
  scp "${ssh_loc}:~/Documents/Data/$remote_dir_list_file" "~/Documents/Data/"   #AB Move that file to local://~/Documents/Data/. This is a reversal of the pattern suggested in the RFS (which wanted the local SCP'd to the remote), but on actually writing the code, this method dramatically simplifies things, improving code quality without altering functionality
  local_dir_list_file=$(get_Documents_Data_TLDs 'main')                         #AB Make a list of directories in  local://~/Documents/Data/ that follow the YYYY-MM-DD pattern. This variable stores the filename
  cd ~/Documents/Data
  difference_file=$(compare_directory_list_files "$remote_dir_list_file" "$local_dir_list_file") #AB Get the name of a file just created in ~/Documents/Data (since that's where the function ran) containing the data directories on the remote (RPi) that are not on the local (main) device.
  scp "$difference_file" "${ssh_loc}:~/Documents/Data/"                         #AB move the difference file over to the RPi
  ssh_send "zip_specified_directories ~/Documents/Data/$difference_file"        #AB On the RPi, zip all the directories in the difference file (that is, all the directories which exist only on the RPi/remote and not on the G16/main computer/local)
  

}


main
