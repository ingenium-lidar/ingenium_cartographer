#!/bin/bash

#AB To download this script, use:
# wget -O install.sh https://tinyurl.com/ingenium-lidar-install

#AB To run this script remotely, without downloading it first, use:
# bash <(curl -L tinyurl.com/ingenium-lidar-install)

#AB Running the above command with the "sl" parameter (explained below) would look like:
# bash <(curl -L tinyurl.com/ingenium-lidar-install) sl


parameter=$1 #AB take the parameter passed to the script


function print_help() { #AB This function prints the help text
    echo '
------------------------------------------------------------------------------------------HELP PAGE FOR install.sh------------------------------------------------------------------------------------------

Usage: ./install.sh ARGUMENT

A script for installing various specific software packages used by the Ingenium LiDAR team. 


ARGUMENT

    dev-jazzy           Installs the LiDAR team developer tools for ROS2 Jazzy Jalisco. Use only on Ubuntu 24.04.1 LTS Desktop
    dev-humble          Installs the LiDAR team developer tools for ROS2 Humble Hawksbill. Use only on Ubuntu 22.04.5 LTS Desktop
    rpi                 Installs tools for data acquisition ONLY. Use on Raspberry Pi 3 hardware with Ubuntu 24.04.2 LTS Server
    slam                Currently, this installs the LiDAR team developer tools for ROS2 Humble Hawksbill. Eventually, it will install only necessary tools for SLAM. Use only on Ubuntu 22.04.5 LTS Desktop
    -h, --help          Prints this help page
    sl                  ...try it and see
    [NONE]              Prints this help page


EXAMPLE
    
    To install the LiDAR team developer tools for ROS2 Jazzy Jalisco on a clean Ubuntu 24.04.1 LTS Desktop, you would run:
    ./install.sh dev-jazzy


For more details or more help with this script, please see the GitHub README.md file, located at https://github.com/JohannesByle/ingenium_cartographer/blob/jazzy/README.md
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
   
}

echo -e "\e[38;5;196mThis install script will require periodic attention. Please keep an eye on the terminal window and respond to any prompts that may appear. Press enter to acknowledge this message and proceed with the installation.\e[0m"
sleep 2
read -r


if [ $parameter == "dev-jazzy" ]; then #AB Download the Jazzy DAI
    echo "Installing Ingenium LiDAR's dev-jazzy package"
    wget -O ingenium_lidar_installer.sh https://raw.githubusercontent.com/JohannesByle/ingenium_cartographer/refs/heads/jazzy/Default_Apps_Installer.sh

elif [ $parameter == "dev-humble" ]; then #AB Download the Humble DAI
    echo "Installing Ingenium LiDAR's dev-humble package"
    wget -O ingenium_lidar_installer.sh https://raw.githubusercontent.com/JohannesByle/ingenium_cartographer/refs/heads/humble/agent_scripts/Default_Apps_Installer.sh

elif [ $parameter == "rpi" ]; then #AB Download the Jazzy RDAI
    echo "Installing Ingenium LiDAR's rpi package"
    wget -O ingenium_lidar_installer.sh https://raw.githubusercontent.com/JohannesByle/ingenium_cartographer/refs/heads/jazzy/RPi_Default_Apps_Installer.sh

elif [ $parameter == "slam" ]; then #AB Download WSL-DAI, which assumes a blank WSL installation of Ubuntu 22.04 LTS Desktop (no directories, no GUI) and therefore installs a GUI before running the Humble DAI
    echo "slam"
    wget -O ingenium_lidar_installer.sh https://raw.githubusercontent.com/JohannesByle/ingenium_cartographer/refs/heads/humble/agent_scripts/WSL_Default_Apps_Installer.sh

elif [ $parameter == "--help" ] || [ $parameter == "--h" ]; then 
    print_help #AB Print the help page
    
elif [ $parameter == "sl" ]; then
    sudo apt install sl # Install critical dependency
    echo ""
    echo "He he he..."
    sleep 2
    sl

else
    echo "Parameter not recognized. Printing help page..."
    print_help 

fi


if [ $parameter == "dev-jazzy" ] || [ $parameter == "dev-humble" ] || [ $parameter == "rpi" ] || [ $parameter == "slam" ]; then #AB if the script actually downloaded something meaningful...
    rm $0 #AB Delete install.sh
    chmod +x ingenium_lidar_installer.sh #AB Mark the downloaded script as executable
    ./ingenium_lidar_installer.sh #AB Run the downloaded script
    rm ingenium_lidar_installer.sh #AB Delete the now obsolete downloaded script
fi




