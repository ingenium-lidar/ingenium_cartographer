
#AB The word "update" now stands for "apt update and upgrade and autoremove"
alias update="sudo apt update && sudo apt upgrade && sudo apt autoremove"

#AB In every terminal session source ROS Jazzy
source /opt/ros/jazzy/setup.bash

#AB source some SLAM packages
source ~/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash
source ~/Apps/lidar_slam_ros2/ros2_ws/install/setup.bash

#AB Add an alias linking to the helper script that kills all ROS nodes
alias roskill="~/Documents/GitHub/helper_scripts/roskill.sh"

#AB Note that this file exists in ~ only if --omit-gui were used when DAI was run. Otherwise, it should not go to ~, since it overrides helpful linux utilities in a way that will break all systems except WSL
source ~/.wslrc

#AB If the imminent reboot warning file exists, then run it
if [ -f ~/.imminent_reboot_warning ]; then
    . ~/.imminent_reboot_warning
fi