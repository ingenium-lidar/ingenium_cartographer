#!/bin/bash

data_file="$1"
source /opt/ros/jazzy/setup.bash

#AB Launch the node to remap /velodyne_packets (proprietary format) to /velodyne_points (of type sensor_msgs/msg/PointCloud2)
#AB This node has been further custom-edited to remap /velodyne_points to /input_cloud
ros2 launch cartographer_config/velodyne_transform_node-VLP32C-launch_ingenium.py &

#AB Play back the data file, remapping the old IMU topic name to the one that SLAM expects.
ros2 bag play $data_file --remap /gx5/imu/data:=/imu &


: "
Here's some helpful debugging tools:

watch -n 0.5 ros2 topic list
This command will show you all the currently active topics in a nice little terminal UI. 

ros2 topic echo /velodyne_points
This command will show you the data being published on the /velodyne_points topic.

ros2 topic type /velodyne_points
This command will show you the type of message being published on the /velodyne_points topic.
"