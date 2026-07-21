#!/bin/bash

#AB Script to prompt user to return their ethernet address for Velodyne config purposes.

NC='\033[0m' #AB format echo text as "no color"
BOLD_CYAN='\e[1;36m' #AB format echo text as bold cyan
RED='\033[0;31m' #AB format echo text as red

notify-send "get_ethernet_address.sh: User input required!"
echo -e "$BOLD_CYAN Please identify your ethernet port name in the command output below and enter it when prompted: $NC"
echo -e "\e[1;32m$(whoami)@$(hostname)\e[0m:\e[1;34m${PWD/#$HOME/\~}\e[0m$ ip address" #AB this echo looks exactly like start prompt in Terminal, so it looks like the script has exited, ran a new command in terminal, and is continuing. Actually, the script hasn't stopped running, but hopefully this helps the user realize what's going on with ip address. (Also, it's good design because it shows the user visually what we're doing behind the scenes--running ip address.)
sleep 1
echo "----------------------------------------------------------------------------------------------------------------"
ip address #AB Print the user's ip information for them to view.
echo "----------------------------------------------------------------------------------------------------------------"

echo -e "$BOLD_CYAN Enter your ethernet port name: $NC"
if [ -t 0 ]; then
    read -p "> " ethernet < /dev/tty #AB read the user's input from Terminal and store it in a variable called ethernet.
else
    ethernet="eth0"
    echo -e "$RED WARNING! Failed to read user input. Defaulting to eth0 $NC" >&2
    exit 1
fi