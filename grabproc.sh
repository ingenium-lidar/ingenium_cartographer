#!/bin/bash

RED='\033[0;31m' #AB format echo text as red
NC='\033[0m' #AB format echo text as "no color"
BOLD_CYAN='\e[1;36m' #AB format echo text as bold cyan
BOLD='\e[1m' #AB format echo text as bold
LIME='\e[38;5;82m' #AB format echo text as bright green

run_slam=0
ssh_loc="lidar@10.42.0.1"


function parse_args() {
  
  PARSED=$(getopt -o hs --long help,SLAM,ssh: -n "$0" -- "$@") || { print_help; exit 2; }
  eval set -- "$PARSED"

  while true; do
    case "$1" in
      -h|--help) print_help; exit 0 ;; #AB This is technically breaking the spec, which calls for -h _not_ to exit, but that seems nonsensical to me after reading more about CLIs, so I'm going to ignore the RFS on this point. 
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

  local computer_name=$1 #AB must be either "main" or "rpi"
  local output_file="${computer_name}_extant_data_directories_$(date "+%F_%H:%M").txt"
  local cwd=$(pwd)
  cd "$HOME/Documents/Data" #AB This is default filesystem, so we can assume it exists
  touch "$output_file" #AB Create an output file

  shopt -s nullglob #AB Set *s to not interpret literally if ~/Documents/Data is empty

  local dirs=(*/) #AB Get a list of all directories in current location (~/Documents/Data)
 
  for dir in "${dirs[@]}"; do                                 #AB Loop through all the directories in the dirs array
      dir="${dir%/}"                                          #AB Strip the trailing slash
      if [[ "$dir" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then   #AB Big nasty RegExp. Basically, it says "if directory is of the pattern ####-##-## where #s are numbers and - is a literal -"
          echo "$dir" >> "$output_file"                         #AB Append each matching directory name from dirs to the output file, each on its own line
      fi
  done

  shopt -u nullglob #AB Set *s to interpret normally in future

  cd "$cwd" #AB Return to where the program was at the start of the function
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
        in_main_list["$filename"]=1
    done

    # --- Compute the difference: items in array1 but NOT in array2 ------------
    local difference=() #AB Define a difference array

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
  local cwd=$(pwd)

  cd ~/Documents/Data
  #AB Loop through all the directories in the file passed to the function and zip them all
  for filename in "${dirs_to_zip[@]}"; do
      zip -r "${filename}.zip" "$filename"
  done

  cd "$cwd"
}


function CD_RoM() {

  cd ~/Documents/Data && rm "$@"
}


function copy_zips_to_local() {

  local zips_file=$1
  local zips_array
  local rsync_error_code
  readarray -t zips_array < "$zips_file"

  for filename in "${zips_array[@]}"; do
      rsync -avzc "${ssh_loc}:${HOME}/Documents/Data/${filename}.zip" "${HOME}/Documents/Data/" #AB Note that rsync with -c handles checksum verification automatically! Yay!
      rsync_error_code=$?
      if [[ $rsync_error_code -eq 0 ]]; then #AB If the transfer worked, delete the file that was transferred
        ssh_send "CD_RoM -rf $filename"
        ssh_send "CD_RoM ${filename}.zip"
      else
        echo "${RED}Failed to transfer $filename. rsync exited with code $rsync_error_code!${NC}" >&2
      fi
  done
}


function extract_and_record_zips() {

    local zips_file=$1
    local cwd=$(pwd)
    local zips_array
    readarray -t zips_array < "$zips_file"
    local transfer_record=".transferred-$(date "+%F")"

    cd ~/Documents/Data
    touch "$transfer_record"
    for filename in "${zips_array[@]}"; do
      unzip "${filename}.zip"
      local unzip_error_code=$?
      if [[ $unzip_error_code -eq 0 ]]; then #AB If the extraction worked, delete the original .zip file
        rm "${filename}.zip"
      else
        echo "${RED}Failed to extract $filename. unzip exited with code $unzip_error_code!${NC}" >&2
      fi
      echo "$filename" >> "$transfer_record"
    done
    
    cd "$cwd"
}


function run_SLAM() {

    local zips_file=$1
    local cwd=$(pwd)
    local zips_array
    readarray -t zips_array < "$zips_file"
    cd ~/Documents/Data

    for filename in "${zips_array[@]}"; do
      ~/Documents/GitHub/ingenium_cartographer/process.sh "$filename"
    done

    cd "$cwd"
}


function main(){

  #AB Declare local variables
  local local_dir_list_file
  local remote_dir_list_file
  local difference_file
  local cwd=$(pwd)

  #AB Copy the appropriate files over from the RPi (remote) to the main (local) device.
  parse_args                                                                    #AB Parse script input
  remote_dir_list_file=$(ssh_send "get_Documents_Data_TLDs 'rpi'")              #AB Make a list of directories in remote://~/Documents/Data/ that follow the YYYY-MM-DD pattern. This variable stores the filename
  scp "${ssh_loc}:${HOME}/Documents/Data/$remote_dir_list_file" "${HOME}/Documents/Data/"   #AB Move that file to local://~/Documents/Data/. This is a reversal of the pattern suggested in the RFS (which wanted the local SCP'd to the remote), but on actually writing the code, this method dramatically simplifies things, improving code quality without altering functionality
  local_dir_list_file=$(get_Documents_Data_TLDs 'main')                         #AB Make a list of directories in  local://~/Documents/Data/ that follow the YYYY-MM-DD pattern. This variable stores the filename
  cd ~/Documents/Data
  difference_file=$(compare_directory_list_files "$remote_dir_list_file" "$local_dir_list_file") #AB Get the name of a file just created in ~/Documents/Data (since that's where the function ran) containing the data directories on the remote (RPi) that are not on the local (main) device.
  scp "$difference_file" "${ssh_loc}:${HOME}/Documents/Data/"                   #AB move the difference file over to the RPi
  ssh_send "zip_specified_directories ${HOME}/Documents/Data/$difference_file"  #AB On the RPi, zip all the directories in the difference file (that is, all the directories which exist only on the RPi/remote and not on the G16/main computer/local)
  copy_zips_to_local "$difference_file"                                         #AB Use rsync (like scp, but slower and more reliable) to copy the remote zips to the local device and remove them from the remote
  extract_and_record_zips "$difference_file"                                    #AB Extract the transported zips and record their existence

  #AB If the run_slam option has been enabled, run SLAM!
  if [[ "$run_slam" -eq 1 ]]; then
    run_SLAM "$difference_file"
  fi

  echo "${BOLD_CYAN}grabproc.sh has finished running!${NC}"

}


main
