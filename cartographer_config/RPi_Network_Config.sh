#!/bin/bash

#FK run immediately after running the RPi_Default_Apps_Installer.sh script and its reboot

#---------------------------------------------CONTINUE CONFIGURING NETWORK---------------------------------------------

read -p "Enter password for hotspot: " hotspot_password #AB Ask the user to enter a password for the hotspot. 

nmcli device wifi hotspot ifname wlan0 ssid Hotspot4 password $hotspot_password #FK tells NetworkManager to create a connection profile for a hotspot, on the network interface (aka device) with the name (ifname = interface name) wlan0, with an ssid of Hotspot 4 (so that Hotspot4 is the name that appears for people wishing to connect to it), with a certain password
#FK tells NetworkManager to create a connection profile for a hotspot, 
# on the network interface (aka device) with the name (ifname = interface name) wlan0, 
# with an ssid of Hotspot 4 (so that Hotspot4 is the name that appears for people wishing to connect to it),
# with a certain password 
nmcli connection modify id Hotspot connection.autoconnect yes
#FK tells NetworkManager to edit the hotspot’s connection profile so that it will make the hotspot automatically on startup
nmcli connection modify id Hotspot connection.autoconnect-priority 1
#FK make the autoconnect priority greater than 0 so that the hotspot takes priority over other connections
#FK at this point, after a reboot, the hotspot should automatically start on start and before login.

reboot