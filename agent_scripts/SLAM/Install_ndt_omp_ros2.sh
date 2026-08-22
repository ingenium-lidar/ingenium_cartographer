#!/bin/bash

#---------------------------------------------INSTALL ndt_omp_ros2---------------------------------------------


#FK Note: since the lidar_slam_ros2 workspace depends on the ndt_omp_ros2 workspace, ndt_omp_ros2 has to be installed first, which is why this section (INSTALL ndt_omp_ros2) comes before the next section (INSTALL lidar_slam_ros2)

#FK Install the ndt_omp_ros2 workspace's source code
cd ~/Apps/ndt_omp_ros2/ros2_ws/src
git clone https://github.com/rsasaki0109/ndt_omp_ros2.git -b humble #FK note: I'm NOT sure about this, but I think that this installs one software package, called ndt_omp_ros2, into the ndt_omp_ros2 workspace

#FK Build the ndt_omp_ros2 workspace
cd ~/Apps/ndt_omp_ros2/ros2_ws #FK change directory to the root of the workspace you want to build
colcon build --executor sequential #FK use the "colcon build" command to hopefully build a set of packages from the correctly set up workspace
#FK For easier debugging, used "--executor sequential" to make things not happen simultaneously

#FK Reboot
#FK colcon documentation says that issues can happen if you source and build the same workspace in the same terminal
#FK so, if we reboot after building each workspace, no issues should happen 
#FK @TODO use Joseph's recent work to reboot the terminal midway through the script and automatically run the rest of the script

echo -e "\e[38;5;5m If you got deprecation warnings and such, but nothing labeled 'error' or something else really serious, do not worry. Everything is OK. \033[0m"


