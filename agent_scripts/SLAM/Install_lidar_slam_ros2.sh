#!/bin/bash

#---------------------------------------------INSTALL lidar_slam_ros2---------------------------------------------


#AB Install the lidar_slam_ros2 package's source code
cd $HOME/Apps/lidar_slam_ros2/ros2_ws/src
git clone --recursive https://github.com/rsasaki0109/lidar_slam_ros2 -b jazzy
#FK @TODO check to see whether we want to use jazzy, or instead the default branch for this repo (develop) is the one we want to use, since the jazzy branch seems to be very associated with humble
touch $HOME/Apps/lidar_slam_ros2/ros2_ws/src/lidar_slam_ros2/Thirdparty/ndt_omp_ros2/COLCON_IGNORE #AB Tell colcon to ignore the ndt_amp_ros2 package which comes bundled with the git repo


#AB Install packages that lidar_slam_ros2 depends on
rosdep update
cd $HOME/Apps/lidar_slam_ros2/ros2_ws
source $HOME/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash #FK in case it's necessary for rosdep to recognize that we have the workspace
rosdep install --from-paths src --ignore-src -r -y

#FK Build the lidar_slam_ros2 workspace
source $HOME/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash #FK source the ndt_omp_ros2 workspace
#FK Reasoning for the above command:
#FK Since lidar_slam_ros2 needs ndt_omp_ros2 (according to lidar_slam_ros2's README.md),
#FK I assume that they are "chained workspaces" (a colcon term)
#FK @TODO check the above assumption
#FK More about chained workspaces: https://colcon.readthedocs.io/en/released/user/using-multiple-workspaces.html
#FK And if this assumption is correct,
#FK ndt_omp_ros2 must be sourced before building lidar_slam_ros2.
cd $HOME/Apps/lidar_slam_ros2/ros2_ws #FK change directory to the root of the workspace you want to build
colcon build --executor sequential --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release #FK use the colcon build command to hopefully build a set of packages from the correctly set up workspace   
#FK For easier debugging, used "--executor sequential" to make things not happen simultaneously
#FK Used the rest of the command following lidar_slam_ros2's README.md 

#FK Set up lidar_slam_ros2 prep to happen whenever the terminal opens
# echo "source $HOME/Apps/lidar_slam_ros2/ros2_ws/install/setup.bash" >> ~/.bashrc #FK make it so that whenever the graphical terminal opens, source lidar_slam_ros2, so that it can be run soon if desired

#FK Note: if ndt_omp_ros2 is chained correctly (which I assume is true),
#FK you don't need to source ndt_omp_ros2 in order to run lidar_slam_ros2,
#FK which is why I didn't add a source command for ndt_omp_ros2 to the bashrc.

#FK Reboot
#FK colcon documentation says that issues can happen if you source and build the same workspace in the same terminal
#FK so, if we reboot after building each workspace, no issues should happen 
#FK @TODO use Joseph's recent work to reboot the terminal midway through the script and automatically run the rest of the script


