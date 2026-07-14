#!/bin/bash

input_file="$1"
output_dir_name=$(basename -s .db3 "$input_file")



#---------------------------------------------SOURCE RELEVANT PACKAGES---------------------------------------------


source /opt/ros/jazzy/setup.bash
source ~/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash
source ~/Apps/lidarslam_ros2/ros2_ws/install/setup.bash



#---------------------------------------------LAUNCH TRANSFORM PUBLISHER AND SLAM---------------------------------------------


#AB Publish the relevant transforms from the urdf file
# TODO: [WARN] [1783512779.897357455] [robot_state_publisher]: No robot_description parameter, but command-line argument available.  Assuming argument is name of URDF file.  This backwards compatibility fallback will be removed in the future.
ros2 run robot_state_publisher robot_state_publisher cartographer_config/lidar_robot.urdf &

#AB Launch the SLAM node
ros2 launch lidarslam lidarslam.launch.py main_param_dir:=cartographer_config/lidarslam_ingenium.yaml &


#---------------------------------------------REMAP AND TRANSLATE TOPICS---------------------------------------------


#AB Launch the node to remap /velodyne_packets (proprietary format) to /velodyne_points (of type sensor_msgs/msg/PointCloud2)
ros2 launch /opt/ros/jazzy/share/velodyne_pointcloud/launch/velodyne_transform_node-VLP32C-launch.py & 

#AB Pass the packets published on /velodyne_points by the transform node to the /input_cloud topic read by the SLAM node. 
ros2 run topic_tools relay /velodyne_points /points_raw & 

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



#---------------------------------------------MOVE FILES TO APPROPRIATE LOCATION---------------------------------------------


#AB Note that these are a temporary measure, and do not necessarily comply with the Default Filesystem Standard.
mkdir -p ~/Documents/Data/$output_dir_name

mv map.pcd ~/Documents/Data/$output_dir_name/map.pcd
mv map_projector_info.yaml ~/Documents/Data/$output_dir_name/map_projector_info.yaml
mv pose_graph.g2o ~/Documents/Data/$output_dir_name/pose_graph.g2o
mv pointcloud_map/ ~/Documents/Data/$output_dir_name/pointcloud_map/

echo "Map saved to ~/Documents/Data/$output_dir_name/map.pcd"



#---------------------------------------------DEBUGGING: CONVERT g2o AND pcd TO poly AND ply---------------------------------------------

#AB If last color file does not exist, create it

if [ ! -f cartographer_config/.last_color_used.txt ]; then
    echo "(255,0,0)" > cartographer_config/.last_color_used.txt
fi

last_color=$(cat cartographer_config/.last_color_used.txt)

#AB If the last color was red, move to green, if it was green, move to blue, if it was blue, move to red

if [ "$last_color" == "(255,0,0)" ]; then
    echo "(0,255,0)" > cartographer_config/.last_color_used.txt
    new_color="(0,255,0)"
elif [ "$last_color" == "(0,255,0)" ]; then
    echo "(0,0,255)" > cartographer_config/.last_color_used.txt
    new_color="(0,0,255)"
else
    echo "(255,0,0)" > cartographer_config/.last_color_used.txt
    new_color="(255,0,0)"
fi

#AB Convert the g2o file to a poly file
~/Documents/GitHub/SLAM_testing/tools/g2o-to-poly.py ~/Documents/Data/$output_dir_name/pose_graph.g2o ~/Documents/Data/$output_dir_name/pose_graph.poly

#AB Convert the pcd file to a ply file of different color than the previous two
~/Documents/GitHub/SLAM_testing/tools/pcd-to-colored-ply.py ~/Documents/Data/$output_dir_name/map.pcd "$new_color"