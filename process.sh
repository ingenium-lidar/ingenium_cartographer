#!/bin/bash


input_file="$1"

source ~/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash
source ~/Apps/lidarslam_ros2/ros2_ws/install/setup.bash

#AB Publish the relevant transforms from the urdf file
ros2 run robot_state_publisher robot_state_publisher cartographer_config/lidar_stick.urdf &

#AB Launch the SLAM node
ros2 launch lidarslam lidarslam.launch.py &

#AB Play back the data file
./play.sh "$input_file" 

#AB When play.sh is done, announce that the program is done
echo "Bag fully processed, press any key to exit"
read -r 

#AB After the user has acknowledged that the program is done, try to save the map
ros2 service call /map_save std_srvs/Empty