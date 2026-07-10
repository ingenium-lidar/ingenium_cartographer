#!/bin/bash

input_file="$1"



#---------------------------------------------SOURCE RELEVANT PACKAGES---------------------------------------------


source /opt/ros/jazzy/setup.bash
source ~/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash
source ~/Apps/lidarslam_ros2/ros2_ws/install/setup.bash



#---------------------------------------------LAUNCH TRANSFORM PUBLISHER AND SLAM---------------------------------------------


#AB Publish the relevant transforms from the urdf file
# TODO: [WARN] [1783512779.897357455] [robot_state_publisher]: No robot_description parameter, but command-line argument available.  Assuming argument is name of URDF file.  This backwards compatibility fallback will be removed in the future.
ros2 run robot_state_publisher robot_state_publisher cartographer_config/lidar_stick.urdf &

#AB Launch the SLAM node
ros2 launch lidarslam lidarslam.launch.py &



#---------------------------------------------REMAP AND TRANSLATE TOPICS---------------------------------------------


#AB Launch the node to remap /velodyne_packets (proprietary format) to /velodyne_points (of type sensor_msgs/msg/PointCloud2)
ros2 launch /opt/ros/jazzy/share/velodyne_pointcloud/launch/velodyne_transform_node-VLP32C-launch.py & 

#AB Pass the packets published on /velodyne_points by the transform node to the /input_cloud topic read by the SLAM node. 
ros2 run topic_tools relay /velodyne_points /input_cloud & 

#AB Rename the IMU topic to match what the SLAM node expects.  
ros2 run topic_tools relay /gx5/imu/data /imu & 



#---------------------------------------------PLAY DATA AND SAVE MAP---------------------------------------------


#AB Play back the data file
ros2 bag play $input_file

#AB When the bag play is done, announce that the program is done
echo "Bag fully processed, press any key to exit"
read -r 

#AB After the user has acknowledged that the program is done, try to save the map
ros2 service call /map_save std_srvs/Empty