#!/bin/bash



#---------------------------------------------INSTALL BASIC PACKAGES & CONFIGURE DIRECTORY STRUCTURE---------------------------------------------


#FK For debugging purposes...
# bash ~/Documents/GitHub/ingenium_cartographer/agent_scripts/Uninstall_SLAM.sh #FK clean up any previous installation stuff
#FK @TODO remove above line when done with debugging
#FK @TODO for debugging purposes, use pipes or arrows to save in a file all of the stdout and stderr from running this script

#FK Basic workspace facts:
#FK --
#FK A workspace represents a grouping of multiple software packages that should be installed and tested together
#FK A workspace is a directory (or, it has a root directory) with specific things inside it
#FK --
#FK Within its root directory are subdirectories containing its parts:
#FK Source code of all software packages, in the "src" subdirectory
#FK Some data that makes future builds go faster, in the "build" subdirectory
#FK A lot of data from previous builds and tests, in the "log" subdirectory
#FK The installed software and shell scripts which enable you to use it, in the "install" subdirectory
#FK --
#FK For more info, see https://colcon.readthedocs.io/en/released/user/what-is-a-workspace.html#

#FK Create some directories for each ROS 2 workspace
#FK The ndt_omp_ros2 workspace
mkdir -p ~/Apps/ndt_omp_ros2 #FK a neatly named storage for it
mkdir ~/Apps/ndt_omp_ros2/ros2_ws #FK the root directory of the workspace
mkdir ~/Apps/ndt_omp_ros2/ros2_ws/src #FK directory for the source code
#The lidar_slam_ros2 workspace
mkdir -p ~/Apps/lidar_slam_ros2 #FK a neatly named storage for it
mkdir ~/Apps/lidar_slam_ros2/ros2_ws #FK the root directory of the workspace
mkdir ~/Apps/lidar_slam_ros2/ros2_ws/src #FK directory for the source code

#FK Source the version of ros, in case needed later
source /opt/ros/jazzy/setup.bash #FK source the version of ros

#FK Install and set up colcon and rosdep
# curl -s https://packagecloud.io/install/repositories/dirk-thomas/colcon/script.deb.sh | sudo bash #FK the colcon documentation has installation instructions which say to do this before installing colcon stuff



#FK 2026-07-08 added the above step to DAI
#AB 2026-07-17 added the commented code below to Install_Jazzy.sh
# sudo apt install python3-colcon-common-extensions -y #AB 2026-06-15 added this installer to DAI
# sudo apt install python3-rosdep -y #AB install rosdep, which I guess doens't come  by default! NB! python3-rosdep2 is only for Debian--python3-rosdep is for Ubuntu 
# #AB 2026-06-15 added the above installer to DAI
# sudo rosdep init #AB turn on rosdep
# rosdep update  #AB update rosdep



# #---------------------------------------------INSTALL ndt_omp_ros2---------------------------------------------


cd $HOME/Documents/GitHub/ingenium_cartographer/agent_scripts/SLAM/
./Install_ndt_omp_ros2.sh

# #FK Note: since the lidar_slam_ros2 workspace depends on the ndt_omp_ros2 workspace, ndt_omp_ros2 has to be installed first, which is why this section (INSTALL ndt_omp_ros2) comes before the next section (INSTALL lidar_slam_ros2)

# #FK Install the ndt_omp_ros2 workspace's source code
# cd ~/Apps/ndt_omp_ros2/ros2_ws/src
# git clone https://github.com/rsasaki0109/ndt_omp_ros2.git -b humble #FK note: I'm NOT sure about this, but I think that this installs one software package, called ndt_omp_ros2, into the ndt_omp_ros2 workspace

# #FK Build the ndt_omp_ros2 workspace
# cd ~/Apps/ndt_omp_ros2/ros2_ws #FK change directory to the root of the workspace you want to build
# colcon build --executor sequential #FK use the "colcon build" command to hopefully build a set of packages from the correctly set up workspace
# #FK For easier debugging, used "--executor sequential" to make things not happen simultaneously

# #FK Reboot
# #FK colcon documentation says that issues can happen if you source and build the same workspace in the same terminal
# #FK so, if we reboot after building each workspace, no issues should happen 
# #FK @TODO use Joseph's recent work to reboot the terminal midway through the script and automatically run the rest of the script

# echo -e "\e[38;5;5m If you got depreciation warnings and such, but nothing labeled 'error' or something else really serious, do not worry. Everything is OK. \033[0m"



#---------------------------------------------INSTALL lidar_slam_ros2---------------------------------------------


cd ..
./reboot+.sh SLAM/Install_lidar_slam_ros2.sh

# #AB Install the lidar_slam_ros2 package's source code
# cd ~/Apps/lidar_slam_ros2/ros2_ws/src
# git clone --recursive https://github.com/rsasaki0109/lidar_slam_ros2 -b jazzy
# #FK @TODO check to see whether we want to use jazzy, or instead the default branch for this repo (develop) is the one we want to use, since the jazzy branch seems to be very associated with humble
# touch ~/Apps/lidar_slam_ros2/ros2_ws/src/lidar_slam_ros2/Thirdparty/ndt_omp_ros2/COLCON_IGNORE #AB Tell colcon to ignore the ndt_amp_ros2 package which comes bundled with the git repo


# #AB Install packages that lidar_slam_ros2 depends on
# cd ~/Apps/lidar_slam_ros2/ros2_ws
# source ~/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash #FK in case it's necessary for rosdep to recognize that we have the workspace
# rosdep install --from-paths src --ignore-src -r -y

# #FK Build the lidar_slam_ros2 workspace
# source ~/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash #FK source the ndt_omp_ros2 workspace
# #FK Reasoning for the above command:
# #FK Since lidar_slam_ros2 needs ndt_omp_ros2 (according to lidar_slam_ros2's README.md),
# #FK I assume that they are "chained workspaces" (a colcon term)
# #FK @TODO check the above assumption
# #FK More about chained workspaces: https://colcon.readthedocs.io/en/released/user/using-multiple-workspaces.html
# #FK And if this assumption is correct,
# #FK ndt_omp_ros2 must be sourced before building lidar_slam_ros2.
# cd ~/Apps/lidar_slam_ros2/ros2_ws #FK change directory to the root of the workspace you want to build
# colcon build --executor sequential --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release #FK use the colcon build command to hopefully build a set of packages from the correctly set up workspace   
# #FK For easier debugging, used "--executor sequential" to make things not happen simultaneously
# #FK Used the rest of the command following lidar_slam_ros2's README.md 

# #FK Set up lidar_slam_ros2 prep to happen whenever the terminal opens
# echo "source ~/Apps/lidar_slam_ros2/ros2_ws/install/setup.bash" >> ~/.bashrc #FK make it so that whenever the graphical terminal opens, source lidar_slam_ros2, so that it can be run soon if desired

# #FK Note: if ndt_omp_ros2 is chained correctly (which I assume is true),
# #FK you don't need to source ndt_omp_ros2 in order to run lidar_slam_ros2,
# #FK which is why I didn't add a source command for ndt_omp_ros2 to the bashrc.

# #FK Reboot
# #FK colcon documentation says that issues can happen if you source and build the same workspace in the same terminal
# #FK so, if we reboot after building each workspace, no issues should happen 
# #FK @TODO use Joseph's recent work to reboot the terminal midway through the script and automatically run the rest of the script



# #---------------------------------------------ADD ALIASES ETC---------------------------------------------

# source ~/.bashrc #AB source bashrc as a courtesy, so that aliases etc are ready as soon as installation finishes
# echo -e "\e[38;5;82mSLAM installation complete.\033[0m"
