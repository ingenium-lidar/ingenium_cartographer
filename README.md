# ingenium_cartographer

&nbsp; &nbsp; &nbsp; This branch of the repository contains bash scripts and config files for slamming data for the Wheaton College Tel Shimron lidar project. This branch is built on ROS2 Jazzy Jalisco. As of this writing (May 2026) this branch is NOT complete, and NOT functional.


![Screenshot](blanchard.png)



## Installation Instructions

0. Select the variant of this package that you want to install.

    The valid arguments are: 

    - `dev-jazzy`
    - `dev-humble` [DEPRECATED!]
    - `rpi`
    - `slam` 
    - `sl`
    - `--help`

    The `--help` option provides more information about the different options. 

    `dev-jazzy` is intended for use on the Ubuntu 24.04.1 LTS Desktop developer laptop for a LiDAR project. 

    `dev-humble` is intended for an Ubuntu 22.04.5 LTS Desktop developer project which requires ROS Humble (in our case, this exists to facilitate work with LIO-SAM). 

    `rpi` is intended for use on an Ubuntu 24.04.2 LTS Server installation on a Raspberry Pi 3. It exclusively installs the dependencies and packages needed for recording data from the LiDAR puck and IMU. 

    `slam` is currently almost identical to `dev-humble`, except that it assumes a WSL installation and installs Gnome GUI before running `dev-humble`. 

    For more details on `sl`, see the help menu.


1. Once you have decided which variant you would like to run, insert the relevant argument into the following template:

    `bash <(curl -L tinyurl.com/ingenium-lidar-install) [arg]`

    For example, to print the help menu without installing anything, I would run

    `bash <(curl -L tinyurl.com/ingenium-lidar-install) --help` in terminal.

    To install the ROS Jazzy-flavored development environment, I would run 

    `bash <(curl -L tinyurl.com/ingenium-lidar-install) --dev-jazzy`

    Ommitting a parameter is the same as calling `--help`. 

2. If these are not working, there is an alternative method below. 

## Instructions for Gathering and Processing Data

0. Connect your LiDAR Hardware (this is tested with a Velodyne VLP-32C Ultra Puck) and IMU (this is tested with a LORD Microstrain 3DM-GX5-15/3DM-GX5-AR) to the data gathering device. Run `./record_to_bag.sh`. This should procduce a .mcap file in `~/Documents/Data`

1. On the fastest available computer, run `./process_bag.sh /path/to/your/mcap/file.mcap`. [NOTE: The dependencies for this script are not included in the minimal installation for Raspberry Pi!] [NOTE: this script is not yet functional!]



## Instructions for Downloading a Single File from GitHub with the Command Line

1. On the GitHub website, navigate to the file you want to download and open the preview

2. On the upper right of the page, select "Raw" and copy the URL

3. On your device, run

`wget -O [new_file_name] https://raw.githubusercontent.com/[my_user_name]/[my_repository]/refs/heads/[my_branch]/[name_of_my_file]`

For example, to download `RPi_Default_Apps_Installer.sh`, run:

`wget -O RPi_Default_Apps_Installer.sh https://raw.githubusercontent.com/JohannesByle/ingenium_cartographer/refs/heads/jazzy/RPi_Default_Apps_Installer.sh`


## Alternative Installation Instructions

If you'd rather not run a random bash script straight off the web, you can use this method to download and inspect the relevant file before you run it. 

0. Use wget to download `install.sh` from the internet. We provide a tinyurl link to simplify this process. The appropriate command is

    `wget -O install.sh https://tinyurl.com/ingenium-lidar-install`

1. Mark the downloaded script as executable by running `chmod +x install.sh`

2. Run the script with the appropriate argument to install a particular set of software packages from this repository. The valid arguments are: 

    - `dev-jazzy`
    - `dev-humble`
    - `rpi`
    - `slam` 
    - `sl`
    - `--help`

    The `--help` option provides more information about the different options. `dev-jazzy` is intended for use on the Ubuntu 24.04.1 LTS Desktop developer laptop for a LiDAR project. `dev-humble` is intended for an Ubuntu 22.04.5 LTS Desktop developer project which requires ROS Humble (in our case, this exists to facilitate work with LIO-SAM). `rpi` is intended for use on an Ubuntu 24.04.2 LTS Server installation on a Raspberry Pi 3. It exclusively installs the dependencies and packages needed for recording data from the LiDAR puck and IMU. `slam` is currently almost identical to `dev-humble`, except that it assumes a WSL installation and installs Gnome GUI before running `dev-humble`. For more details on `sl`, see the help menu.

    To set up the dev-jazzy system, you would run

    `./install.sh dev-jazzy`
    
    These scripts frequently prompt sudo at various stages of the process. This is normal. 