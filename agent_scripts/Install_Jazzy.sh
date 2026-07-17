#!/bin/bash

#AB ROS Jazzy Installation Script, copied from https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html
#AB to use ROS in a given terminal session, run source /opt/ros/jazzy/setup.bash
cwd=$(pwd)
NC='\033[0m' #AB format echo text as "no color"
LIME='\e[38;5;82m' #AB format echo text as bright green
echo -e "$LIME *^* Start of Install_Jazzy.sh$NC "



#---------------------------------------------INSTALL ROS JAZZY---------------------------------------------

echo "Updating apt..."
sleep 1
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

echo "Installing universe repository..."
sleep 1
sudo apt install -y software-properties-common
sudo add-apt-repository universe -y

echo "Configuring system..."
sleep 1
sudo apt update # && sudo apt install -y curl #AB Moved to DAI 2026-07-17
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
curl --fail --retry 5 --retry-delay 5 --retry-all-errors --location -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $UBUNTU_CODENAME)_all.deb" # If using Ubuntu derivates use $UBUNTU_CODENAME
sudo dpkg -i /tmp/ros2-apt-source.deb

echo "Updating apt a second time..."
sleep 1
sudo apt update
sudo apt upgrade -y

echo "Installing ros-jazzy-desktop..."
sleep 1
sudo apt install -y ros-jazzy-desktop

echo "ROS2 Jazzy installation complete."
sleep 1

cd $cwd



#---------------------------------------------INSTALL ROS-HOSTED APT PACKAGES---------------------------------------------


echo -e "$LIME Updating and upgrading apt...$NC "
sudo apt update && sudo apt upgrade -y
sleep 1

echo -e "$LIME Installing rosbag2...$NC"
sleep 1
sudo apt-get install -y ros-jazzy-rosbag2
#AB Removed this 2026-07-17 because I think it duplicates python3-colcon-common-extensions
# echo "Installing colcon..."
# sleep 1
# sudo apt install -y colcon & #AB A build tool for ROS2

#AB We install these here and not above with the other apt installs because they require ROS Jazzy to be installed first
echo -e "$LIME Installing hardware drivers...$NC "
sudo apt install ros-jazzy-velodyne -y #AB Install the Velodyne driver. It's in a stack hosted (I believe) on the ROS website.
sudo apt install ros-jazzy-microstrain-inertial-driver -y #AB Install the IMU driver. These drivers are now maintained as part of the built-in ROS package manager! 

echo -e "$LIME Installing Colcon and rosdep...$NC "
sudo apt install python3-colcon-common-extensions -y #AB Installs both colcon and common extensions for colcon, the ROS build tool.
sudo apt install python3-rosdep -y                   #AB Install rosdep, a tool for managing dependencies in ROS
sudo rosdep init #AB turn on rosdep
rosdep update  #AB update rosdep

echo -e "$LIME Finished installing ROS-dependent packages.$NC "
echo -e "$LIME End of Install_Jazzy.sh *^*$NC"
