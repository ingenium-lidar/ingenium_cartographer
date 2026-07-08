#!/bin/bash


input_file="$1"

source ~/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash
source ~/Apps/lidarslam_ros2/ros2_ws/install/setup.bash

ros2 launch lidarslam lidarslam.launch.py &

./play.sh "$input_file" 

ros2 service call /map_save std_srvs/Empty

echo "Bag fully processed, press any key to exit"
read -r 
