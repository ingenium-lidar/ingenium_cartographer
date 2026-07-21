#!/bin/bash

set -euo pipefail


verbose=0
force=0
omit_gui=0
package=""
branch="main"
version="2.0.0" #AB Remember: versions go major.minor.patch


function print_help() { #AB This function prints the help text
    cat << 'EOF'
------------------------------------------------------------------------------------------HELP PAGE FOR install.sh------------------------------------------------------------------------------------------

install.sh - A script to set up a computer for one of Ingenium LiDAR's computer systems.
License: GPL-3.0
Version: 2.0.0 (2026-07-21)

SYNOPSIS/USAGE
  ./install.sh <-p|--package <name>> [-b|--branch <name>] [-h|--help] [-v|--verbose] [-q|--quiet] [-f|--force] [--version] [--omit-gui]

DESCRIPTION
  Sets up the Ingenium LiDAR system from scratch on an empty Ubuntu system by automatic script. 

DEPENDENCIES
  Requires wget, getopt
  sl requires apt
  dev-jazzy requires Ubuntu 24.04 LTS Desktop
  rpi-jazzy requires Ubuntu 24.04 LTS Server (only tested on ARM64)

ARGUMENTS
  <-p|--package <name>>    Which variant of our system you wish to install. Valid arguments are `dev-jazzy`, `rpi-jazzy`, and `sl`. Required. More about these below.
  [-b|--branch <name>]     Branch of ingenium_cartographer to install. Defaults to `main`, the latest stable branch.
  [-h|--help]              Prints this help page.
  [-v|--verbose]           Sets verbosity level to 2 (highest).
  [-q|--quiet]             Sets verbosity level to 0 (lowest). Overrides -v.
  [-f|--force]             Skip all prompts that it is possible to skip.
  [--version]              Print the script version and exit.
  [--omit-gui]             Applicable to `dev-*` packages only. Causes the installer script to omit all packages which require a graphical user interface. 

EXIT CODES
  0   Success
  1   General error
  2   Invalid argument(s)

VARIANTS

  Currently available:
    dev-jazzy             Set up a developer/"main" computer compatible with ROS 2 Jazzy Jalisco. Requires Ubuntu 24.04 Desktop. Includes SLAM, VS Code, other GUI tools.
    rpi-jazzy             Set up an ultra-minimal computer compatible with ROS 2 Jazzy Jalisco. Requires Ubuntu 24.04 Server. Includes only bare-minimum data-acquisition tools. Intended to be run on a Raspberry Pi. 
    sl                    Test the functionality of this installer script without significantly altering your device or directory structure. 

  Upcoming:
    dev-lyrical           Will be the same as dev-jazzy, but updated for compatibility with ROS 2 Lyrical Luth.
    rpi-lyrical           Will be the same as rpi-jazzy, but updated for compatibility with ROS 2 Lyrical Luth.

  No longer available:
    dev-humble            Deprecated in May 2026, no longer supported since July 2026. 
    slam                  Deprecated in May 2026, no longer supported since July 2026. 

WARNINGS
  These installer scripts are fairly destructive of existing data, since they conform the filesystem to match our team's filesystem specification. It is strongly
  recommended that you run these scripts only on clean, new installations of Ubuntu.


For more details or more help with this script, please see our GitHub README at https://github.com/ingenium-lidar/ingenium_cartographer/.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
EOF
   exit 0
}


function dev-jazzy() {
    wget -O ingenium_lidar_installer.sh "https://raw.githubusercontent.com/ingenium-lidar/ingenium_cartographer/refs/heads/$branch/Default_Apps_Installer.sh"
    chmod +x ingenium_lidar_installer.sh #AB Mark the downloaded script as executable
    ./ingenium_lidar_installer.sh "$1" "$2" "$3" "$4" #AB Run the downloaded script
    rm ingenium_lidar_installer.sh #AB Delete the now obsolete downloaded script
}


function rpi-jazzy() {
    wget -O ingenium_lidar_installer.sh "https://raw.githubusercontent.com/ingenium-lidar/ingenium_cartographer/refs/heads/$branch/RPi_Default_Apps_Installer.sh"
    chmod +x ingenium_lidar_installer.sh #AB Mark the downloaded script as executable
    ./ingenium_lidar_installer.sh "$1" "$2" "$3" #AB Run the downloaded script
    rm ingenium_lidar_installer.sh #AB Delete the now obsolete downloaded script
}


function fn_sl() {
    sudo apt install sl -y # Install critical dependency
    echo ""
    echo "He he he..."
    sleep 2
    sl
    exit 0
}


function print_version() {
    echo "$version"
    exit 0
}



PARSED=$(getopt -o hvqfp:b: --long help,verbose,quiet,force,package:,branch:,version,omit-gui -n "$0" -- "$@")
eval set -- "$PARSED"


while true; do
  case "$1" in
    -h|--help) print_help; shift ;;
    -v|--verbose) verbose=2; shift ;;
    -q|--quiet) verbose=0; shift ;;
    -f|--force) force=1; shift ;;
    -p|--package) package="$2"; shift 2 ;;
    -b|--branch) branch="$2"; shift 2 ;;
    --version) print_version; shift ;;
    --omit-gui) omit_gui=1; shift ;;
    --) shift; break ;;
    *) echo "Unexpected option: $1" >&2; print_help; exit 2 ;;
  esac
done



echo -e "\e[38;5;196mThis install script will require periodic attention. Please keep an eye on the terminal window and respond to any prompts that may appear. Press enter to acknowledge this message and proceed with the installation.\e[0m"
sleep 2
read -r



if [[ -z "$package" ]]; then
    echo "--package is required! Printing the help menu..." >&2
    print_help
    exit 2

elif [[ "$package" == "dev-jazzy" ]]; then
    dev-jazzy "$verbose" "$force" "$branch" "$omit_gui"

elif [[ "$package" == "rpi-jazzy" ]]; then
    rpi-jazzy "$verbose" "$force" "$branch"

elif [[ "$package" == "sl" ]]; then
    fn_sl
    
fi