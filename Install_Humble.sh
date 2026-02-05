#!/bin/bash

#FK from this documentation: https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debs.html
#FK meant to be used on Ubuntu 22.04

#FK has worked on Finn's computer, 8/1/2025, windows subsystem for linux with Ubuntu 22.04.5 LTS

sudo apt update
sudo apt upgrade
sudo apt autoremove
cwd=$(pwd) #AB save the current working directory

echo "Beginning setup..."
sleep 2

#AB Install universe repository
sudo apt install -y software-properties-common
sudo add-apt-repository universe

#AB get the latest version of the ros-apt-source
sudo apt update && sudo apt install -y curl
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $UBUNTU_CODENAME)_all.deb"
sudo dpkg -i /tmp/ros2-apt-source.deb

sudo apt update
sudo apt upgrade
sudo apt autoremove

#AB Install ROS Humble Desktop
echo "Installing ros humble desktop..."
sleep 2
sudo apt install -y ros-humble-desktop

cd ~
echo "Adding alias run_humble to system ~/.bashrc file"
echo 'alias run_humble="source /opt/ros/humble/setup.bash"' >> ~/.bashrc

cd $cwd

echo "Install_Humble.sh has finished running now."

