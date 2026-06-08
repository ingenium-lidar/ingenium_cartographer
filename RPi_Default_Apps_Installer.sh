#!/bin/bash

#AB Run on a clean Ubuntu Server 24.04.2 LTS system
#AB This script has been majorly updated since it was last tested from scratch. Please verify functionality and report bugs to the other devs.


#---------------------------------------------UPDATE THE SYSTEM AND INSTALL PACKAGES---------------------------------------------


#FK updates and upgrades
sudo apt update
sudo apt upgrade
sudo apt autoremove

sudo apt install -y network-manager #AB add utility for managing networks
sudo apt install -y net-tools #AB add another utility for managing networks
sudo apt-get install -y git #AB install git, just in case it is not already installed
sudo apt install -y yamllint #AB a tool to check the syntax of YAML files
sudo apt install -y sl #AB Install sl, an alias for ls


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

cd .. #AB Return to the ingenium_cartographer directory
cd agent_scripts
rm Install_LIO-SAM.sh Install_SLAM.sh Install_rsasaki_slam.sh
mv Install_Jazzy.sh ..

cd .. #AB Return to the ingenium_cartographer directory
for file in *; do #AB Iterate through all files within it
  if [[ "$file" == *.sh ]]; then #AB If the file is a bash script (i.e., if it ends in .sh)...
    chmod +x $file #AB ...then mark it as executable
  fi
done


cd cartographer_config #FK go into the config folder
sudo mv use_network_manager.yaml /etc/netplan #FK move file that makes Ubuntu Server use NetworkManager into the correct folder


sudo chmod +x RPi_Network_Config.sh #FK mark the second installer script as executable
sudo mv RPi_Network_Config.sh ~ #FK move second installer script to the main directory
sudo mv .bash_aliases ~ #AB Move the .bash_aliases file in cartographer_config to the home directory. 
#AB Clean up all files in cartographer_config that aren't needed for the ROS2 system
mv microstrain_launch_ingenium.py ..
cd ..
sudo rm -rfd cartographer_config
mkdir cartographer_config
mv microstrain_launch_ingenium.py cartographer_config



#---------------------------------------------INSTALL ROS JAZZY AND DRIVERS---------------------------------------------


#AB Install ROS Jazzy
./Install_Jazzy.sh 

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y ros-jazzy-velodyne                    #AB Install the LiDAR driver. This and the following are not a regular part of APT, but they are accessible to APT after Jazzy has been installed
sudo apt-get install -y ros-jazzy-microstrain-inertial-driver #AB Install the IMU driver. 



#---------------------------------------------UPDATE THE SYSTEM AGAIN---------------------------------------------


sudo apt update
sudo apt upgrade
sudo apt autoremove



#---------------------------------------------EXIT---------------------------------------------


echo "RPi_Default_Apps_Installer.sh has finished running now."
sleep 2
echo "System will reboot in..."
echo 5 && sleep 1
echo 4 && sleep 1
echo 3 && sleep 1
echo 2 && sleep 1
echo 1 && sleep 1
reboot