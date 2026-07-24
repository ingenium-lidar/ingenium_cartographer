#!/bin/bash

RED='\033[0;31m' #AB format echo text as red
NC='\033[0m' #AB format echo text as "no color"
BOLD_CYAN='\e[1;36m' #AB format echo text as bold cyan
BOLD='\e[1m' #AB format echo text as bold
LIME='\e[38;5;82m' #AB format echo text as bright green

run_slam=0
ssh_loc="lidar@10.42.0.1"



function parse_args() {
  #######################################
  # Parses arguments passed to the file.
  # Exits 0 on help and 2 on unexpected argument.
  # Globals:
  #   run_slam
  #   ssh_loc
  # Outputs:
  #   Writes errors to STDERR
  #   Edits globals as appropriate
  #######################################
  
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
  #######################################
  # Prints the help menu.
  #######################################

    cat << 'EOF'
----------------------------HELP PAGE FOR grabproc.sh----------------------------

grabproc.sh - A script to automatically copy data files from an RPi to a main computer and (optionally) SLAM them. 
License: GPL-3.0
Version: 0.0.1 (2026-07-23)

Usage:
  `./grabproc.sh [-h|--help] [-s|--SLAM] [--ssh <username>@<ip_address>]

Details:
  Use -h or --help to print this text and exit the program.
  Use -s or --SLAM to request that the program SLAM all .mcap or .db3 files copied over from the RPi
  Use --ssh to specify a host and ip other than the default (lidar@10.42.0.2)

NB:
  Remember to be connected to the RPi's hotspot before running this. 

---------------------------------------------------------------------------------
EOF
}



function ssh_send() {
  #######################################
  # Runs a Bash function on the remote device
  # Globals:
  #   ssh_loc
  # Arguments:
  #   $1 - command to be run on the remote in the format "<function_name> [args]"
  # Outputs:
  #   Writes errors to STDERR
  # Returns:
  #   255 if on SSH connection error
  #   ? error code of the command passed if that failed
  #   output of the called function
  #######################################

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
  #######################################
  # Gets the names of all the directories in ~/Documents/Data that match the pattern "/*/YYYY-MM-DD/"
  # Arguments:
  #   $1 - name of the computer the function is being run on. Must be either "main" (ie local) or "rpi" (ie remote)
  # Outputs:
  #   Writes a \n-separated list to $output_file (generated from the computer name and the data)
  # Returns:
  #   The path of the output file relative to . 
  #######################################

  local computer_name=$1 #AB must be either "main" or "rpi"
  local output_file="${computer_name}_extant_data_directories_$(date "+%F_%H:%M").txt"
  local cwd=$(pwd)
  cd "$HOME/Documents/Data" #AB This is default filesystem, so we can assume it exists
  touch "$output_file" #AB Create an output file

  shopt -s nullglob #AB Set *s to not interpret literally if ~/Documents/Data is empty

  local dirs=(*/)                                                       #AB top-level year dirs, e.g. "2026/"
  for year_dir in "${dirs[@]}"; do
      local date_dirs=("${year_dir}"*/)                                 #AB day dirs, eg. "2026-07-24"
      for dir in "${date_dirs[@]}"; do
          dir="${dir%/}"                                                #AB "2026/2026-07-24"
          local date_only="${dir#"$year_dir"}"                          #AB "2026-07-24" for the regex check
          if [[ "$date_only" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
              echo "$dir" >> "$output_file"                             #AB write "2026/2026-07-24" 
          fi
      done
  done

  shopt -u nullglob #AB Set *s to interpret normally in future

  cd "$cwd" #AB Return to where the program was at the start of the function
  echo "$output_file"
}



function compare_directory_list_files() {
  #######################################
  # Compares two files full of directory names and returns a list of all the ones in the first not in the second
  # Arguments:
  #   $1 - path to the list of matching directories on the remote machine
  #   $2 - path to the list of matching directories on the local machine
  # Outputs:
  #   Writes difference to $output_file (computed using the date)
  # Returns:
  #   Filepath of the output file, relative to .
  #######################################

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
  #######################################
  # Compresses the specified directories to zip files
  # Arguments:
  #   $1 - a file containing \n-separated names of directories which are to be compressed
  # Outputs:
  #   1 zip file per line in the input file
  #######################################

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
  #######################################
  # Goes to ~/Documents/Data and deletes what you specify there
  # Arguments:
  #   $@ - anything you want to pass to rm
  #######################################

  cd ~/Documents/Data && rm "$@"
}



function copy_zips_to_local() {
  #######################################
  # Copies zip files of specified names to a local device and verifies them by checksum
  # Globals:
  #   ssh_loc
  # Arguments:
  #   $1 - file containing a \n-separated list of the zip files which are to be moved, without the .zip extension
  # Outputs:
  #   Copies zip files to the local://~/Documents/Data
  #   Deletes both the zip file and the directory it was generated from on the remote
  # Returns:
  #   ? error code of rsync if that is not 0
  #######################################

  local zips_file=$1
  local zips_array
  local rsync_error_code
  readarray -t zips_array < "$zips_file"

  for filename in "${zips_array[@]}"; do
      local dest_path="${HOME}/Documents/Data/${filename}.zip"
      mkdir -p "$(dirname "$dest_path")"
      rsync -avzc "${ssh_loc}:${HOME}/Documents/Data/${filename}.zip" "$dest_path" #AB Note that rsync with -c handles checksum verification automatically! Yay!
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
  #######################################
  # Extracts zip files specified in a file passed to the function and records their names in a hidden file
  # Arguments:
  #   $1 - a file containing a \n-separated list of zip files to be unzipped (without the .zip extension)
  # Outputs:
  #   Writes errors to STDERR
  #   Appends the names of all files in the read array to a .transferred file, whose name is computed using the date
  #   1 extracted directory for each zip file present whose name is in the original file
  #######################################

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
      echo "$filename" >> "$transfer_record" #AB We're recording whether the .zip made it, not whether the zip extracted or not. 
    done
    
    cd "$cwd"
}



function run_SLAM() {
  #######################################
  # Runs process.sh on every file in any subdirectory of the passed directories with a .mcap or .db3 extension.
  # Arguments:
  #   $1 - a file containing a \n-separated list of directories in whose subdirectories to search for raw data files
  # Outputs:
  #   The output of process.sh
  #######################################

  #AB Example of a filepath conforming to DFS R4:
  #   /home/lidar/Documents/Data/2026/2026-07-24/94/94_RAW_1784885704/94_RAW_1784885704_0.mcap

    local day_dirs_file=$1
    local cwd=$(pwd)
    local day_dirs_array
    readarray -t day_dirs_array < "$day_dirs_file"
    cd ~/Documents/Data

    for filename in "${day_dirs_array[@]}"; do #AB filename covers 2026/2026-07-24/ in this examle
      ~/Documents/GitHub/ingenium_cartographer/process.sh "$HOME/Documents/Data/$filename/*/*/*.mcap"
    done

    cd "$cwd"
}



function main(){
  #######################################
  # Runs a Bash function on the remote device
  # Globals:
  #   ssh_loc
  #   run_slam
  # Returns:
  #   A batch of files copied from the remote and processed according to the params passed to the file
  #######################################

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
