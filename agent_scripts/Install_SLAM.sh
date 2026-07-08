#!/bin/bash



#---------------------------------------------INSTALL BASIC PACKAGES & CONFIGURE DIRECTORY STRUCTURE---------------------------------------------


source /opt/ros/jazzy/setup.bash #FK source the version of ros


mkdir -p ~/Apps/ndt_omp_ros2/ros2_ws/src #FK create the directory for the ROS 2 workspace of ndt_omp_ros2, and the subdirectory for its source code
echo -e "\e[38;5;5m If you got a 'fatal' error saying ros2_ws already exists, do not worry. Everything is OK. \033[0m"
mkdir -p ~/Apps/lidarslam_ros2/ros2_ws/src #FK create the directory for the ROS 2 workspace of lidarslam_ros2, and the subdirectory for its source code
echo -e "\e[38;5;5m If you got a 'fatal' error saying ros2_ws already exists, do not worry. Everything is OK. \033[0m"

sudo apt install python3-colcon-common-extensions -y #AB 2026-06-15 added this installer to DAI
sudo apt install python3-rosdep -y #AB install rosdep, which I guess doens't come  by default! NB! python3-rosdep2 is only for Debian--python3-rosdep is for Ubuntu 
#AB 2026-06-15 added the above installer to DAI
sudo rosdep init #AB turn on rosdep
rosdep update  #AB update rosdep



#---------------------------------------------INSTALL ndt_omp_ros2---------------------------------------------


#FK Note: since the lidarslam_ros2 workspace depends on the ndt_omp_ros2 workspace, ndt_omp_ros2 has to be installed first, which is why this section (INSTALL ndt_omp_ros2) comes before the next section (INSTALL lidarslam_ros2)

#FK Install the ndt_omp_ros2 workspace's source code
cd ~/Apps/ndt_omp_ros2/ros2_ws/src
git clone https://github.com/rsasaki0109/ndt_omp_ros2.git -b humble #FK note: I'm NOT sure about this, but I think that this installs one software package, called ndt_omp_ros2, into the ndt_omp_ros2 workspace

#FK Build the ndt_omp_ros2 workspace
cd ~/Apps/ndt_omp_ros2/ros2_ws #FK move to the root of the workspace, so that "colcon build" works correctly
colcon build --executor sequential --cmake-clean-first #FK colcon build a set of packages from the correctly set up workspace ndt_omp_ros2, assuming we're in the root of that workspace

echo -e "\e[38;5;5m If you got depreciation warnings and such, but nothing labeled 'error' or something else really serious, do not worry. Everything is OK. \033[0m"



#---------------------------------------------INSTALL lidarslam_ros2---------------------------------------------


#FK Source the ndt_omp_ros2 package, since this workspace (lidarslam_ros2) depends on it, and therefore needs to source it before installation
source ~/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash

#AB Install the lidarslam_ros2 package's source code
cd ~/Apps/lidarslam_ros2/ros2_ws/src
git clone --recursive https://github.com/rsasaki0109/lidarslam_ros2
touch ~/Apps/lidarslam_ros2/ros2_ws/src/lidarslam_ros2/Thirdparty/ndt_omp_ros2/COLCON_IGNORE #AB Tell colcon to ignore the ndt_amp_ros2 package which comes bundled with the git repo

cd ..
rosdep install --from-paths src --ignore-src -r -y #AB Automatically install dependencies of the SLAM repo

#FK Build the lidarslam_ros2 package
cd ~/Apps/lidarlsam_ros2/ros2_ws #FK move to the root of the workspace, so that "colcon build" works correctly
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release #FK build a set of packages from the correctly set up lidarslam_ros2 workspace, assuming we're in the root of that workspace


source ~/Apps/lidarslam_ros2/ros2_ws/install/setup.bash #FK source lidarslam_ros2, so that it can be run soon if desired



#---------------------------------------------ADD ALIASES ETC---------------------------------------------

source ~/.bashrc #AB source bashrc as a courtesy, so that aliases etc are ready as soon as installation finishes
echo -e "\e[38;5;82mSLAM installation complete.\033[0m"


