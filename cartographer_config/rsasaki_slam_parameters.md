# Notes on rsasaki09 SLAM Parameters

This table was copied out of rsasaki09's README.md file, located [here](https://github.com/rsasaki0109/lidar_slam_ros2/blob/jazzy/README.md)

The fifth column was added and annotated by Abraham, and provides 
comments that he thinks are relevant to our application.

## params

- frontend(scan-matcher) 

|Name|Type|Default value|Description|Abraham's Notes For Ingenium|
|---|---|---|---|---|
|registration_method|string|"NDT"|"NDT" or "GICP"|No comment|
|ndt_resolution|double|5.0|resolution size of voxel[m]|No comment. Let's stick with the default on this one for now|
|ndt_num_threads|int|0|threads using ndt(if `0` is set, maximum alloawble threads are used.)(The higher the number, the better, but reduce it if the CPU processing is too large to estimate its own position.)|We'll need to determine this experimentally on the G16 specifically. Let's start with 0|
|gicp_corr_dist_threshold|double|5.0|the distance threshold between the two corresponding points of the source and target[m]|No comment|
|trans_for_mapupdate|double|1.5|moving distance of map update[m]|No comment|
|vg_size_for_input|double|0.2|down sample size of input cloud[m]|I think this relates to how much of the input cloud to randomly discard. Not sure why it's a double... we don't need to SLAM in real time, so if we can afford to do 0 downsampling, hopefully that might increase quality|
|vg_size_for_map|double|0.05|down sample size of map cloud[m]|See above|
|use_min_max_filter|bool|false|whether or not to use minmax filter|No comment|
|scan_max_range|double|100.0|max range of input cloud[m]|This one is important. Let's use the defaults from our old SLAM (see slam.lua)|
|scan_min_range|double|1.0|min range of input cloud[m]|This one is important. Let's use the defaults from our old SLAM (see slam.lua)|
|scan_period|double|0.1|scan period of input cloud[sec](If you want to compound imu, you need to change this parameter.)|Idk what he means about compounding IMU, but that's a hardware-specific parameter--that is, ours will be unique to our VLP-32C puck. Again, let's check slam.lua and see what's written there. This parameter should be required by all SLAM algorithms and should be universal|
|map_publish_period|double|15.0|period of map publish[sec]|No comment|
|num_targeted_cloud|int|10|number of targeted cloud in registration(The higher this number,  the less distortion.)|Let's make this number high!|
|debug_flag|bool|false|Whether or not to display the registration information|On at the start, off during production|
|set_initial_pose|bool|false|whether or not to set the default pose value in the param file|So, I know our last SLAM assumed that the puck was at 0,0,0 and perfectly level. We fixed this with georectification in post-processing, but I know it could cause the pointcloud to be initially tilted from its true axis. (Actually, maybe it was the IMU that assumed that? I'm actually not sure. Test this with the IMU by reading its data live as it boots. Does it always assume that the orientation its at when it powers on is 0?)|
|initial_pose_x|double|0.0|x-coordinate of the initial pose value[m]|See lidar_stick.urdf for our IMU-puck translation if needed.|
|initial_pose_y|double|0.0|y-coordinate of the initial pose value[m]|Ditto.|
|initial_pose_z|double|0.0|z-coordinate of the initial pose value[m]|Ditto.|
|initial_pose_qx|double|0.0|Quaternion x of the initial pose value|Yay quaternions! See lidar_stick.urdf for our IMU-puck rotation quaternions if needed.|
|initial_pose_qy|double|0.0|Quaternion y of the initial pose value|Ditto.|
|initial_pose_qz|double|0.0|Quaternion z of the initial pose value|Ditto.|
|initial_pose_qw|double|1.0|Quaternion w of the initial pose value|Ditto.|
|publish_tf|bool|true|Whether or not to publish tf from global frame to robot frame|Honestly no idea. Leave as default for now? I don't think publishing that could possibly hurt anything|
|use_odom|bool|false|whether odom is used or not for initial attitude in point cloud registration|No comment|
|use_imu|bool|false|whether 9-axis imu(Angular velocity, acceleration and orientation must be included.) is used or not for point cloud distortion correction.(Note that you must also set the `scan_period`.)|I forget whether our IMUs are 9-axis or 6-axis. I think they might be 9. If 9, consider using this. Try both ways. If ours are 6, I would be hesistant to use this|
|debug_flag|bool|false|Whether or not to display the registration information|Turn on at the start, off in production|


- backend(graph-based-slam)

|Name|Type|Default value|Description|Abraham's Notes For Ingenium|
|---|---|---|---|---|
|registration_method|string|"NDT"|"NDT" or "GICP"|No idea what this means|
|ndt_resolution|double|5.0|resolution size of voxel[m]|This should probably match the similar param in the SLAM above?|
|ndt_num_threads|int|0|threads using ndt(if `0` is set, maximum alloawble threads are used.)|See note on SLAM above. With repeated params, make sure that this doesn't inherit params from the SLAM--if it does, then let this inherit, and only change the ones here that aren't set by the SLAM|
|voxel_leaf_size|double|0.2|down sample size of input cloud[m]|See above|
|loop_detection_period|int|1000|period of searching loop detection[ms]|This is a complicated param to set, with far-reaching repurcussions for which walls the SLAM idenfifies as beign the same. Messing this up could completely wreck how the SLAM works, so edit with care.|
|threshold_loop_closure_score|double|1.0| fitness score of ndt for loop clousure|No idea. Also, _[sic]_|
|distance_loop_closure|double|20.0| distance far from revisit candidates for loop clousure[m]|See note on loop_detection_period|
|range_of_searching_loop_closure|double|20.0|search radius for candidate points from the present for loop closure[m]|See note on loop_detection_period|
|search_submap_num|int|2|the number of submap points before and after the revisit point used for registration|No idea what this means. See https://xkcd.com/2501/|
|num_adjacent_pose_cnstraints|int|5|the number of constraints between successive nodes in a pose graph over time| See above. Also, _[sic]_|
|use_save_map_in_loop|bool|true|Whether to save the map when loop close(If the map saving process in loop close is too heavy and the self-position estimation fails, set this to `false`.)|No comment|
