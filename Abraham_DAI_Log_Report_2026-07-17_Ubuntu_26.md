# Errors & Warnings Summary

## Major

1. Around line 184, DAI referenced nmcli, which it had not yet installed, causing an error. 

2. Somehow, curl broke after 9 bytes while trying to fetch the Jazzy .deb packages at /tmp/ros2-apt-source.deb, causing cascading failures throughout the system as Jazzy failed to install. We need to include some sort of safety buffer to make curl try again if it fails in this way. That's at line 22 of Install_Jazzy. 

## Minor

1. At line 38 of DAI, gdm-settings failed to install. This is an OS customization tool, so it might very well be that it failed because my WSL environment does not include Gnome, which deals with the GUI side of Linux. Either way, no biggie! I suppose that, in the unlikely case that it's utterly dead, we won't be able to put the Tel Shimron logo on the login screen of new devices anymore!

2. At line 52 of DAI, package python3.12-venv, which helps to create Python virtual environments, failed to install. I might just remove this one and note that once upon a time we installed this tool, but that this specific version is no longer relevant to us. After all, we shouldn't be needing venvs anytime soon! 

## Optimizations

1. At line 119, sudo apt upgrade prompted `Continue? [Y/n]`. This should be fixed if possible. 

2. Snap install emacs took a million years. Can we do away with that one? (Firefox was also slow, but we can't exactly do away with Firefox!)

3. I think that `Install_Jazzy.sh` line 16 (which reads `sudo add-apt-repository universe`) was responsible for producing a `Press [ENTER] to continue or Ctrl-c to cancel.` prompt which occured at line 9008 of the log. This should be fixed if possible. 

## Safety

1. We should switch apt over to apt-get--there are a billion warnings about it!

## Notes on the Claude Report

The Claude report mentions a bunch of failures related to Gnome, but that's OK! WSL doesn't include Gnome because it doesn't use a graphical interface, so obviously setting the desktop theme to "dark with blue accents" doesn't run. That's not an issue because of how I was testing the system. 


# Appendix A: DAI Manual Log

This log was written down while DAI was in progress.

## Y/n Prompt 1 at:

```
  libssh2-1t64               xxd

Not upgrading yet due to phasing:
  python3-software-properties  software-properties-common

Summary:
  Upgrading: 72, Installing: 0, Removing: 0, Not Upgrading: 2
54 standard LTS security updates
  Download size: 91.2 MB
  Space needed: 678 kB / 1025 GB available

Continue? [Y/n]
```

## Note:

Apt installing Firefox takes _forever!_ What on earth???

Also snapd installing emacs

## Enter prompt #2 at:

```
Get:1 http://archive.ubuntu.com/ubuntu resolute-updates/main amd64 software-properties-common all 0.120.1 [16.6 kB]
Get:2 http://archive.ubuntu.com/ubuntu resolute-updates/main amd64 python3-software-properties all 0.120.1 [28.7 kB]
Fetched 45.3 kB in 1s (50.4 kB/s)
(Reading database ... 103540 files and directories currently installed.)
Preparing to unpack .../software-properties-common_0.120.1_all.deb ...
Unpacking software-properties-common (0.120.1) over (0.120) ...
Preparing to unpack .../python3-software-properties_0.120.1_all.deb ...
Unpacking python3-software-properties (0.120.1) over (0.120) ...
Setting up python3-software-properties (0.120.1) ...
Setting up software-properties-common (0.120.1) ...
Processing triggers for man-db (2.13.1-1build1) ...
Processing triggers for dbus (1.16.2-2ubuntu4) ...
Adding component(s) 'universe' to all repositories.
Press [ENTER] to continue or Ctrl-c to cancel.
```

## Caught an nmcli error manually:

```
 Enter your ethernet port name:
> eth0
./DAI.sh: line 184: nmcli: command not found
```

## On First Login after Running DAI:

```
-bash: /opt/ros/jazzy/setup.bash: No such file or directory
-bash: /home/lidar/Apps/ndt_omp_ros2/ros2_ws/install/setup.bash: No such file or directory
-bash: /home/lidar/Apps/lidarslam_ros2/ros2_ws/install/setup.bash: No such file or directory
lidar@Abraham-PC:/mnt/c/Users/abrah$
```