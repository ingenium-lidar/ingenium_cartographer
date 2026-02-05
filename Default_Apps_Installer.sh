#!/bin/bash

#AB Bash script to reinstall all the scripts and apps necessary for the project. Run on a fresh Ubuntu 24.04.* LTS install.
#AB NOTE: This script primarily installs a long series of "developer tools"--things necessary for the project developers (eg. CloudCompare, IDEs), but not necessarily needed on every RPi. To set up a new RPi, see RPi-Default-Apps-Installer.sh
#AB: This script was most recently run with no fatal errors on April 2 2026

RED='\033[0;31m' #AB format echo text as red
NC='\033[0m' #AB format echo text as "no color"
BOLD_CYAN='\e[1;36m' #AB format echo text as bold cyan
BOLD='\e[1m' #AB format echo text as bold
#AB To print all possible colors, uncomment the following lines:
# for code in {0..255}
#     do echo -e "\e[38;5;${code}m"'\\e[38;5;'"$code"m"\e[0m"
#   done
ethernet=enp152s0  #AB Replace enp152s0 with the name of your ethernet port, which can be found using the ip address command



#---------------------------------------------INSTALL BASIC PACKAGES---------------------------------------------
echo -e "\e[38;5;82mInstalling base packages...\033[0m"
sleep 1

echo -e "\e[38;5;82mUpdating and upgrading apt repositories..."
sudo apt update
sudo apt upgrade
echo -e "\e[38;5;82mInstalling htop, openssh, gnome-keyring, rpi-imager, gnome-tweaks, snapd, yamllint, gdm-toolkit, net-tools, pip, python3.12-venv, sl, tree, cloudcompare, blender, gparted, dosfstools, mtools, and vim via apt...\033[0m"
sudo apt install -y htop #AB Disk space monitor
sudo apt install -y openssh-server #AB SSH client
sudo apt-get install -y gnome-keyring #AB Install a secure cryptographic library needed by VS Code
sudo apt install -y rpi-imager #AB a software for burning OSes onto SD cards for use in a Raspberry Pi
sudo apt install -y gnome-tweaks #AB An OS customization tool
sudo apt install -y snapd #AB A package manager
sudo apt install -y yamllint #AB a tool to check the syntax of YAML files
sudo apt install -y gdm-settings libglib2.0-dev-bin #AB Another OS customization tool
sudo apt install -y net-tools
sudo apt install -y python3-pip #AB Install pip, Python's package manager.
sudo apt install -y python3.12-venv #AB Install a package to allow creating python virtual environments
sudo apt install -y sl #AB Install sl, an alias for ls
sudo apt install -y tree #AB A fancy directory structure printer
#AB VERY IMPORTANT NOTE: We used to use snap to install CloudCompare and Blender, but snap bundled packages incompatible with our graphics drivers and everything crashed. Use apt instead. It's safer.
sudo apt install -y cloudcompare #AB Install CloudCompare (a point-cloud processing software)
sudo apt install -y blender #AB Install Blender (a 3D modeling software)
sudo apt install -y gparted #AB A partition manager
sudo apt install -y dosfstools mtools #AB Install dependencies for gparted on the previous line which let it work with FAT32 formatting
sudo apt install -y vim #AB Install vim, _the_ standard text editor for Terminal (if not the most user friendly)
echo -e "\e[38;5;82mInstalling and configuring git...\033[0m"
sudo apt-get install -y git #AB Install and then configure git (a source control software for coders)
git config --global user.email "ingenium.lidar@outlook.com"
git config --global user.name "Ingenium-LiDAR"

echo -e "\e[38;5;82mInstalling VS Code, Firefox, CloudCompare, and Blender via snap...\033[0m"
sudo snap install firefox
sudo snap refresh firefox #AB Update the default-installed Firefox to the latest version
sudo snap install gh #FK/AB install GitHub command line interface
sudo snap install emacs #AB Install emacs, for all the people who know that instead of vim
sudo snap install --classic code #AB Visual Studio Code, a git-integrated IDE for basically all computer languages
code --password-store="gnome-libsecret" #AB (attempt to) configure VS Code to use Gnome Keyring (opening code in the process...)



#---------------------------------------------CREATE DEFAULT DIRECTORY STRUCTURE---------------------------------------------


echo -e "\e[38;5;82mCreating default directory structure...\033[0m"
mkdir -p ~/Documents/GitHub
mkdir -p ~/Documents/Data
mkdir -p ~/Apps/ros2_ws/src



#---------------------------------------------INSTALL "ingenium_cartographer" REPOSITORY---------------------------------------------


echo -e "\e[38;5;82mInstalling the Ingenium Cartographer repository...\033[0m"
if ! [ -d ~/Documents/GitHub/ingenium_cartographer ]; then #AB If a directory called ingenium_cartographer does not already exist in ~/Documents/GitHub...
    cd ~/Documents/GitHub #AB ...navigate to the ~/Documents/GitHub directory
    git clone https://github.com/JohannesByle/ingenium_cartographer
    sleep 2
    cd ingenium_cartographer #AB Enter the newly cloned repository
    git switch jazzy #AB Switch to the jazzy branch of the ingenium_cartographer repository
else
    cd ingenium_cartographer #AB Else, enter the existing repository
    git pull #AB Update the repository to the latest version
    git switch jazzy #AB Switch to the jazzy branch of the ingenium_cartographer repository 
fi


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




#---------------------------------------------INSTALL ROS2 Jazzy---------------------------------------------


echo -e "\e[38;5;82mInstalling ROS2 Jazzy Jalisco...\033[0m"
cd ~/Documents/GitHub/ingenium_cartographer/agent_scripts #AB Navigate to the ingenium_cartographer/agent_scripts directory.
./Install_Jazzy.sh #AB Run the Install_Jazzy.sh script to install ROS Jazzy 



#---------------------------------------------INSTALL HARDWARE DRIVERS---------------------------------------------


echo -e "\e[38;5;82mInstalling hardware drivers...\033[0m"
sudo apt-get update
sudo apt-get upgrade
sudo apt-get -y install ros-jazzy-velodyne #AB Install the Velodyne driver. It's in a stack hosted (I believe) on the ROS website.
sudo apt-get -y install ros-jazzy-microstrain-inertial-driver #AB Install the IMU driver. These drivers are now maintained as part of the built-in ROS package manager! 



#---------------------------------------------CONFIGURE PORTS AND IP ADDRESSES---------------------------------------------


echo -e "\e[38;5;82mConfiguring ports and IP addresses...\033[0m"
#AB This section rewrites your ethernet IP to be on the same network as the VLP-32C default. If your sensors are not connecting, you're probably on the wrong subnet.
#FK This older line of code is probably unnecessary: sudo ip route add 192.168.1.201 dev enp152s0 #AB Replace enp152s0 with the name of your ethernet port, which can be found by running ip address 
#FK Add a network connection to the ethernet port with the stable ipv4 address 192.168.1.100/24, which is necessary to connect to the VLP-32C LiDAR puck
nmcli connection add type ethernet ifname $ethernet con-name lidar-puck autoconnect yes ipv4.addresses "192.168.1.201" ipv4.method manual



#---------------------------------------------INSTALL VELOVIEW---------------------------------------------


echo -e "\e[38;5;82mInstalling VeloView...\033[0m"
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



#---------------------------------------------INSTALL ROS2 Jazzy---------------------------------------------


echo -e "\e[38;5;82mInstalling lidarslam_ros2...\033[0m"
cd ~/Documents/GitHub/ingenium_cartographer/agent_scripts #AB Navigate to the ingenium_cartographer/agent_scripts directory. 
./Install_SLAM.sh #AB Run the Install_SLAM.sh script to install lidarslam_ros2 



#---------------------------------------------CLEANUP---------------------------------------------


echo -e "\e[38;5;82mCleaning up...\033[0m"

echo 'alias update="sudo apt update && sudo apt upgrade && sudo apt autoremove"' >> ~/.bashrc #AB add the alias update to the system ~/.bashrc file. It will now update, upgrade, and finally autoremove all unnecessary files whenever the command "update" is entered.

echo -ne "Running sudo apt autoremove:\n"
sudo apt autoremove #AB Remove all files not needed in the system. Frees up a variable amount of space (on the Jun 24, 2025 reinstall, I had superfluous firmware. You never know...)

gsettings set org.gnome.desktop.background picture-uri file:~/Documents/GitHub/ingenium_cartographer/blanchard.png #AB Set the desktop background to blanchard.png from the GitHub.

echo -e "\e[38;5;82mDefault_Apps_Installer.sh has finished running now.\033[0m"

cd ~/Documents/GitHub/ingenium_cartographer/agent_scripts
./reboot.sh
