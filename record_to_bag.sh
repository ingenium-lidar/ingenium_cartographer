#!/bin/bash

#---------------------------------------------SOURCE JAZZY AND CONFIGURE ENVIRONMENT VARIABLES---------------------------------------------#


source /opt/ros/jazzy/setup.bash


#AB if the user passed the grid ID as a parameter, use that
if [ -n "$1" ]; then
  grid_id="$1"
else
  echo -ne "\e[1;36mEnter the Grid ID:\n>>> \033[0m"
  read -r grid_id #AB Prompt the user to enter a grid ID, which will be used to name the recorded data bag files.
fi


save_path=~/Documents/Data/$(date +%F)/"$grid_id"_RAW_$(date +%F_%H:%M)
echo -e "\e[1;36mSaving file to $save_path\033[0m"

#AB Publish a static transform from the base frame to the IMU frame of reference. 
#  - Indicate 0 translation (as consistent with the older files from the ROS1 version)
#  - Give a rotation quaterion (same rotation as the ROS1 system). See https://www.andre-gaschler.com/rotationconverter/ for this in Euler angles (RPY) or a rotation matrix.
#  - Specify which two frames are to be linked by this quaternion transform.
ros2 run tf2_ros static_transform_publisher --x 0 --y 0 --z 0 --qx -0.500001 --qy -0.499999 --qz 0.500004 --qw -0.499996 --frame-id base_link --child-frame-id imu_link &



#---------------------------------------------LAUNCH DRIVERS AS DICTATED BY ENVIRONMENT VARIABLES---------------------------------------------#


ros2 launch velodyne_driver velodyne_driver_node-VLP32C-launch.py & #AB Launch the velodyne driver and begin broadcasting on the /velodyne_packets topic

ros2 launch cartographer_config/microstrain_launch_ingenium.py & #AB Launch the IMU driver and begin broadcasting on the /imu/data topic
sleep 1



#---------------------------------------------RECORD DATA AS DICTATED BY ENVIRONMENT VARIABLES---------------------------------------------#


echo -e "\e[1;36mRecording lidar and imu data...\033[0m"
ros2 bag record -o $save_path --storage sqlite3 /imu/data /velodyne_packets & #AB Record the /velodyne_packets and /imu/data topics
sleep 1



#---------------------------------------------END DATA COLLECTION AND CLEAN UP WORKSPACE---------------------------------------------#


echo -e "\e[1;36mCurrently recording, press enter to exit\033[0m"
read -r #AB Wait for an input of any key, then proceed to cleanup

# ./cleanup.sh #AB This  automatically moves all directories starting with "rosbag2_" to the /Documents/Data directory, and creates that directory if it does not exist.

pkill -f ros2 && pkill -f microstrain && pkill -f launch && pkill -f rviz2 #AB forcefully kill ALL ROS2 processes to prevent ghost proceeses from continuing.
sleep 1

echo -e "\e[1;36mThe program has finished running now.\033[0m"
exit


