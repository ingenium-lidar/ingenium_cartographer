#!/bin/bash

#AB Run on a clean Ubuntu Server 24.04.2 LTS system
# This script was last run with no fatal errors on 2026-07-25
# This script was last run with no errors on 2026-07-25


#---------------------------------------------UPDATE THE SYSTEM AND INSTALL APT PACKAGES---------------------------------------------


#FK updates and upgrades
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y

apt_flags=("-y")

apt_packages=(
    git                               #AB a version control tool
    network-manager                   #AB Install network configuration tool (this is nmcli!)
    net-tools                         #AB includes ifconfig and other useful network configuration tools
    sl                                #AB Install sl, an alias for ls
    yamllint                          #AB a tool to check the syntax of YAML files
    zip                               #AB An archive manager
)

for package in "${apt_packages[@]}"; do
    echo ""
    echo ">>> Installing: $package"
    sudo apt-get install "${apt_flags[@]}" "$package" 
done



#---------------------------------------------INSTALL INGENIUM CARTOGRAPHER REPOSITORY---------------------------------------------


mkdir -p ~/Documents/GitHub #AB Create the GitHub directory in the ~/Documents directory. If ~/Documents does not exist, the -p flag creates it also.
cd ~/Documents/GitHub

#AB Clone the ingenium_cartographer repository if it does not already exist
if ! [ -d "ingenium_cartographer" ]; then
    git clone https://github.com/ingenium-lidar/ingenium_cartographer.git
fi

cd ingenium_cartographer


#AB Remove all files in the main directory which are not relevant to data acquisition
rm Default_Apps_Installer.sh display_bag.sh install.sh process_bag.sh subtract.sh blanchard.png
sudo rm -r python_scripts
sudo rm -r gui_scripts

cd ~/Documents/GitHub/ingenium_cartographer/agent_scripts
rm Install_LIO-SAM.sh Install_SLAM.sh Install_rsasaki_slam.sh
mv Install_Jazzy.sh ..


cd ~/Documents/GitHub/ingenium_cartographer/cartographer_config
sudo mv use_network_manager.yaml /etc/netplan #FK move file that makes Ubuntu Server use NetworkManager into the correct folder


sudo mv RPi_Network_Config.sh ~ #FK move second installer script to the main directory
mv microstrain_launch_ingenium.py ..

#AB Clean up all files in cartographer_config that aren't needed for the ROS2 system
cd ~/Documents/GitHub/ingenium_cartographer
sudo rm -rfd cartographer_config
mkdir cartographer_config
mv microstrain_launch_ingenium.py cartographer_config



#---------------------------------------------INSTALL ROS JAZZY---------------------------------------------
 

cd ~/Documents/GitHub/ingenium_cartographer
#AB Install ROS Jazzy
./Install_Jazzy.sh 



#---------------------------------------------UPDATE THE SYSTEM AGAIN---------------------------------------------


sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y



#---------------------------------------------EXIT---------------------------------------------


echo "RPi_Default_Apps_Installer.sh has finished running now."
cd ~/Documents/GitHub/ingenium_cartographer/agent_scripts
./reboot.sh
