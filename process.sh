#!/bin/bash



#---------------------------------------------GET INPUT AND SET GLOBALS---------------------------------------------


input_file="${1:?input_file is required}"                                 # ../..//Data/2026-07-23/92/92_RAW_1784823750_0.mcap
color="$2"
last_color_file="cartographer_config/.last_color_used.txt"


if [ -z "$input_file" ]; then #AB If the $input_file variable is empty, then...
  echo "Usage: $0 <input_mcap> [color]"
  exit 2
fi

input_file="$(realpath "$input_file")"                                    # /home/lidar/Documents/Data/2026-07-23/92/92_RAW_1784823750_0.mcap
if [ ! -f "$input_file" ]; then #AB If $input_file is not a file, then...
  echo "Input file not found: $input_file"
  exit 2
fi


#AB default file for SLAM tuning is at G16://~/Documents/Data/barrows.db3



#---------------------------------------------SOURCE RELEVANT PACKAGES---------------------------------------------


source /opt/ros/jazzy/setup.bash
source ~/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash
source ~/Apps/lidar_slam_ros2/ros2_ws/install/setup.bash



#---------------------------------------------LAUNCH TRANSFORM PUBLISHER AND SLAM---------------------------------------------


#AB Publish the relevant transforms from the urdf file
# TODO: [WARN] [1783512779.897357455] [robot_state_publisher]: No robot_description parameter, but command-line argument available.  Assuming argument is name of URDF file.  This backwards compatibility fallback will be removed in the future.
# TODO: try ros2 run robot_state_publisher robot_state_publisher --ros-args -p robot_description:="$(cat cartographer_config/lidar_robot.urdf)"
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

ros2 bag play "$input_file"

echo "Bag fully processed, press any key to exit"
read -r

#AB After the user has acknowledged that the program is done, try to save the map
ros2 service call /map_save std_srvs/Empty



# FUZZ CODE FOR TESTING PURPOSES
touch map.pcd
touch map_projector_info.yaml
touch pose_graph.g2o
mkdir pointcloud_map/
touch pointcloud_map/a.pcd
touch pointcloud_map/b.pcd
touch pointcloud_map/c.pcd



#---------------------------------------------MOVE FILES TO APPROPRIATE LOCATION---------------------------------------------


#AB Slice the path meticulously into little blocks                        # /home/lidar/Documents/Data/2026-07-23/92/92_RAW_1784823750_0.mcap
IFS='/' read -ra slash_sliced <<< "$input_file"
echo "${slash_sliced[0]}" > /dev/null                                     # home
echo "${slash_sliced[1]}" > /dev/null                                     # lidar
echo "${slash_sliced[2]}" > /dev/null                                     # Documents
echo "${slash_sliced[3]}" > /dev/null                                     # Data
daystamp="${slash_sliced[4]}"                                             # 2026-07-23
grid_id="${slash_sliced[5]}"                                              # 92  
base_file_name="${slash_sliced[6]}"                                       # 92_RAW_1784823750_0.mcap

IFS='_' read -ra underscore_sliced <<< "$base_file_name"
echo "${underscore_sliced[0]}" > /dev/null                                # 92
processing_stage="${underscore_sliced[1]}"                                # RAW
timestamp="${underscore_sliced[2]}"                                       # 1784823750
echo "${underscore_sliced[3]}" > /dev/null                                # 0.mcap



output_dir="${HOME}/Documents/Data/${daystamp}/${grid_id}/${grid_id}_RAW-SLAM_${timestamp}"
echo "output_dir = $output_dir"
mkdir "$output_dir"

mv map.pcd "${output_dir}/${grid_id}_RAW-SLAM_${timestamp}.pcd"
mv map_projector_info.yaml "${output_dir}/${grid_id}_RAW-SLAM_${timestamp}_map_projector_info.yaml"
mv pose_graph.g2o "${output_dir}/${grid_id}_RAW-SLAM_${timestamp}_pose_graph.g2o"
mv pointcloud_map/ "${output_dir}/${grid_id}_RAW-SLAM_${timestamp}_pointcloud_map/"

echo "Map saved to ${output_dir}"



#---------------------------------------------DEBUGGING: CONVERT g2o AND pcd TO poly AND ply---------------------------------------------


if [ -z "$color" ]; then #AB If color parameter is empty...
    if [ ! -f "$last_color_file" ]; then #AB If the $last_color_file does not exist...
        printf '%s\n' "(255,0,0)" > "$last_color_file" #AB create it as default red
    fi

    last_color="$(<"$last_color_file")" #AB Get the last color from the file...
    #AB And move red > green > blue > yellow > magenta > cyan in a loop
    case "$last_color" in
        "(255,0,0)") new_color="(0,255,0)" ;;
        "(0,255,0)") new_color="(0,0,255)" ;;
        "(0,0,255)") new_color="(255,255,0)" ;;
        "(255,255,0)") new_color="(255,0,255)" ;;
        *) new_color="(0,255,255)" ;;
    esac
    printf '%s\n' "$new_color" > "$last_color_file"
else #AB If there _is_ a color parameter, just roll with that
    new_color="$color"
fi

#AB Convert the g2o file to a poly file
~/Documents/GitHub/SLAM_testing/tools/g2o-to-poly.py "$output_dir"/pose_graph.g2o "$output_dir"/pose_graph.poly

#AB Convert the pcd file to a ply file of different color than the previous two
~/Documents/GitHub/SLAM_testing/tools/pcd-to-colored-ply.py "$output_dir"/map.pcd "$new_color"