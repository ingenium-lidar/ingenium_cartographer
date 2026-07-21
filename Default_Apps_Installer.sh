#!/bin/bash

#AB Bash script to reinstall all the scripts and apps necessary for the project. Run on a fresh Ubuntu 24.04.* LTS install.
#AB NOTE: This script primarily installs a long series of "developer tools"--things necessary for the project developers (eg. CloudCompare, IDEs), but not necessarily needed on every RPi. To set up a new RPi, see RPi_Default_Apps_Installer.sh
#AB: This script was most recently run with no fatal errors on April 2 2026

RED='\033[0;31m' #AB format echo text as red
NC='\033[0m' #AB format echo text as "no color"
BOLD_CYAN='\e[1;36m' #AB format echo text as bold cyan
BOLD='\e[1m' #AB format echo text as bold
LIME='\e[38;5;82m' #AB format echo text as bright green
#AB To print all possible colors, uncomment the following lines:
# for code in {0..255}
#     do echo -e "\e[38;5;${code}m"'\\e[38;5;'"$code"m"\e[0m"
#   done

sudo -v #AB prompt for sudo at the beginning, which helps minimize the number of times sudo is prompted later.



#---------------------------------------------INSTALL BASIC PACKAGES---------------------------------------------


echo -e "$LIME Updating and upgrading apt repositories...$NC "
sudo apt update
sudo apt upgrade
sudo apt autoremove

echo -e "$LIME Installing apt packages...$NC "
sleep 1

apt_packages=(
    blender                           #AB Install Blender (a 3D modeling software)
    cloudcompare                      #AB Install CloudCompare (a point-cloud processing software)
    dosfstools                        #AB Install dependency for gparted which lets it work with FAT32 formatting
    firefox                           #AB Install Firefox Web Browser
    gdm-settings                      #AB Another OS customization tool
    git                               #AB a version control tool
    git-lfs                           #AB GitHub Large File Storage, an open source extension to help deal with large files in git commits.
    gnome-keyring                     #AB a secure cryptographic library needed by VS Code
    gnome-tweaks                      #AB An OS customization tool
    gparted                           #AB A partition manager
    htop                              #AB Interactive process viewer
    libglib2.0-dev-bin                #AB A dependency of gdm-settings (and a lot of other things, too, including gnone-tweaks)
    libpcl-dev                        #AB CLI, API, etc for PCL
    mtools                            #AB Install dependency for gparted which lets it work with FAT32 formatting
    net-tools                         #AB includes ifconfig and other useful network configuration tools
    openssh-server                    #AB SSH client
    pcl-tools                         #AB Install pcl ("point cloud library"), used for manipulating point clouds.
    python3-pip                       #AB Install pip, Python's package manager.
    python3.12-venv                   #AB Install a package to allow creating python virtual environments
    python3-colcon-common-extensions  #AB Install colcon, the ROS build tool.
    python3-rosdep                    #AB Install rosdep, a tool for managing dependencies in ROS
    rpi-imager                        #AB a tool for burning OSes onto SD cards for use in a Raspberry Pi
    snapd                             #AB A package manager
    sl                                #AB Install sl, an alias for ls
    tree                              #AB A fancy directory structure printer
    vim                               #AB Install vim, _the_ standard text editor for Terminal (if not the most user friendly)
    yamllint                          #AB a tool to check the syntax of YAML files
)


for package in "${apt_packages[@]}"; do
    echo ""
    echo ">>> Installing: $package"
    sudo apt install -y "$package"
done


echo -e "$LIME Configuring git...$NC "

git config --global user.email "ingenium.lidar@outlook.com"
git config --global user.name "Ingenium-LiDAR-Admin"



echo -e "$LIME Installing snap packages...$NC "

#AB Important note! We used to install CloudCompare and Blender via snap before we realized that something about how snap handles graphics on high-end GPUs was causing the apps to crash. Now we use apt instead.
#AB We also used to snap install firefox, but apt install firefox does the same thing. Now, all of our snaps run with the --classic flag, which gives them permissions that normal snaps don't have.

snap_classic_packages=(
    gh      #FK install GitHub command line interface
    emacs   #AB Install emacs, for all the people who know that instead of vim
    code    #AB Visual Studio Code, a git-integrated IDE for basically all computer languages
)


for package in "${snap_classic_packages[@]}"; do
    echo ""
    echo ">>> Installing: $package"
    sudo snap install --classic "$package"
done



#---------------------------------------------CREATE DEFAULT DIRECTORY STRUCTURE---------------------------------------------


echo -e "$LIME Creating default directory structure...$NC "

mkdir ~/Documents
mkdir ~/Documents/GitHub
mkdir ~/Documents/Data
mkdir ~/Documents/Garbage

mkdir ~/Apps
mkdir -p ~/Apps/ros2_ws/src


cd ~/Documents #AB Clone the RFCS repository, which contains .md files which document work that needs to be done.
git clone https://github.com/ingenium-lidar/RFCs.git

cd ~/Documents/Garbage
touch README.md
echo -e "# Instructions for Garbage Directory \n\n This directory exists for files that are of no value, and can safely be deleted. Use it to test tools that create files, to temporarily store copies of important data files that you're editing, to actually type \`rm -rfd ./*\` for once, etc">README.md



#---------------------------------------------INSTALL "ingenium_cartographer" REPOSITORY---------------------------------------------


echo -e "$LIME Installing the Ingenium Cartographer repository...$NC "
if [ -d ~/Documents/GitHub/ingenium_cartographer ]; then #AB If a directory called ingenium_cartographer already exists in ~/Documents/GitHub...
    sudo rm -rfd ~/Documents/GitHub/ingenium_cartographer #AB ...then delete it, along with all of its contents.
fi

cd ~/Documents/GitHub #AB ...navigate to the ~/Documents/GitHub directory
git clone https://github.com/ingenium-lidar/ingenium_cartographer.git #AB ...and clone the ingenium_cartographer repository from GitHub

cd ingenium_cartographer #AB Navigate to the newly cloned repository
for file in *; do #AB Iterate through all files within it
    if [[ "$file" == *.sh ]]; then #AB If the file ends in .sh (i.e., if it's a bash script)...
        chmod +x "$file" #AB ...then mark it as executable
    elif [ -d "$file" ]; then #AB If the file is a directory...
        for subfile in "$file"/*; do #AB Iterate through all files within the directory
            if [[ "$subfile" == *.sh ]]; then #AB If _that_ file is a bash script...
                chmod +x "$subfile" #AB ...then mark it as executable
            fi #AB This second loop catches all of the scripts in agent_scripts
        done
    fi
done


mv ~/Documents/GitHub/ingenium_cartographer/cartographer_config/.bash_aliases ~ #AB Move the .bash_aliases file in cartographer_config to the home directory



#---------------------------------------------INSTALL ROS2 Jazzy---------------------------------------------


echo -e "$LIME Installing ROS2 Jazzy Jalisco...$NC "
cd ~/Documents/GitHub/ingenium_cartographer/agent_scripts #AB Navigate to the ingenium_cartographer/agent_scripts directory.
./Install_Jazzy.sh #AB Run the Install_Jazzy.sh script to install ROS Jazzy 



#---------------------------------------------INSTALL HARDWARE DRIVERS---------------------------------------------


echo -e "$LIME Updating and upgrading apt...$NC "
sudo apt update && sudo apt upgrade -y
sleep 1

#AB We install these here and not above with the other apt installs because they require ROS Jazzy to be installed first
echo -e "$LIME Installing hardware drivers...$NC "
sudo apt install ros-jazzy-velodyne -y #AB Install the Velodyne driver. It's in a stack hosted (I believe) on the ROS website.
sudo apt install ros-jazzy-microstrain-inertial-driver -y #AB Install the IMU driver. These drivers are now maintained as part of the built-in ROS package manager! 



#---------------------------------------------CONFIGURE PORTS AND IP ADDRESSES---------------------------------------------


echo -e "$LIME Configuring ports and IP addresses...$NC "
#AB This section rewrites your ethernet IP to be on the same network as the VLP-32C default. If your sensors are not connecting, you're probably on the wrong subnet.

source ~/Documents/GitHub/ingenium_cartographer/agent_scripts/get_ethernet_address.sh #AB Run the get_ethernet_address.sh script to prompt the user for their ethernet port name and store it in a variable called ethernet. 
nmcli connection add type ethernet ifname $ethernet con-name lidar-puck autoconnect yes ipv4.addresses "192.168.1.201" ipv4.method manual #FK Add a network connection to the ethernet port with the stable ipv4 address 192.168.1.100/24, which is necessary to connect to the VLP-32C LiDAR puck



#---------------------------------------------INSTALL VELOVIEW---------------------------------------------


echo -e "$LIME Installing VeloView...$NC "
cd ~/Apps

#AB Download VeloView 5.1 for Ubuntu from the web. Update this URL if VeloView ever stops working.
curl "https://www.paraview.org/paraview-downloads/download.php?submit=Download&version=v5.9&type=app&os=Linux&downloadFile=VeloView-5.1.0-Ubuntu18.04-x86_64.tar.gz" --output veloview.tar.gz
tar -xzf veloview.tar.gz #AB Extract it from the archive. Extracts by default to a directory called VeloView-5.1.0-Ubuntu18.04-x86_64
chmod +x "VeloView-5.1.0-Ubuntu18.04-x86_64/bin/VeloView" #AB Make the VeloView binary executable
VELOVIEW_EXEC_PATH="$(pwd)/VeloView-5.1.0-Ubuntu18.04-x86_64/bin/VeloView" #AB Get the absolute path to the executable

#AB Create a Desktop entry file for all users linking to the VeloView binary
sudo bash -c "cat > '/usr/share/applications/veloview.desktop' <<EOF
[Desktop Entry]
Version=1.0
Name=VeloView
Exec=$VELOVIEW_EXEC_PATH
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Graphics;
EOF"

sudo chmod +x "/usr/share/applications/veloview.desktop" #AB Make the desktop file into an executable
rm veloview.tar.gz #AB delete the archive previously downloaded



#---------------------------------------------INSTALL SLAM---------------------------------------------


echo -e "$LIME Installing lidarslam_ros2...$NC "
cd ~/Documents/GitHub/ingenium_cartographer/agent_scripts #AB Navigate to the ingenium_cartographer/agent_scripts directory. 
# ./Install_rsasaki_slam.sh #AB Run the Install_rsasaki_slam.sh script to install lidarslam_ros2 
echo -e "\e[38;5;196m\033[1m DID NOT RUN SLAM INSTALLER. THE RELEVANT LINE OF CODE HAS BEEN COMMENTED UNTIL THE SCRIPT IS COMPLETE $NC "



#---------------------------------------------CONFIGURE UI---------------------------------------------


echo -e "$LIME Setting system colors to dark mode with blue accents...$NC "
#AB Set global color scheme to dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

#AB Configure Terminal theme
UUID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'") #AB Get the current default Terminal profile ID
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$UUID/ use-theme-colors false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$UUID/ palette "['#171421', '#C01C28', '#26A269', '#A2734C', '#12488B', '#A347BA', '#2AA1B3', '#D0CFCC', '#5E5C64', '#F66151', '#33DA7A', '#E9AD0C', '#2A7BDE', '#C061CB', '#33C7DE', '#FFFFFF']" #AB set default dark terminal theme colors
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$UUID/ background-color 'rgb(30,30,30)' #AB Set the background and foreground (text) to the default dark colors
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$UUID/ foreground-color 'rgb(208,207,204)'

#AB Set accent color to blue
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-blue-dark'



#---------------------------------------------CLEANUP---------------------------------------------


echo -e "$LIME Cleaning up...$NC "

echo -ne "Running sudo apt autoremove:\n"
sudo apt autoremove -y #AB Remove all files not needed in the system. Frees up a variable amount of space (on the Jun 24, 2025 reinstall, I had superfluous firmware. You never know...)

gsettings set org.gnome.desktop.background picture-uri file:~/Documents/GitHub/ingenium_cartographer/blanchard.png #AB Set the desktop background to blanchard.png from the GitHub.

echo -e "$LIME Default_Apps_Installer.sh has finished running.$NC "

cd ~/Documents/GitHub/ingenium_cartographer/agent_scripts
./reboot.sh
