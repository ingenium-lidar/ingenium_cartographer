#!/bin/bash
#JD - This script runs once after reboot to finish the hotspot setup.
#------------------------------ENSURE FAILURE IF WE HAVE PROBLEMS----------------------------------------

#JD - This makes the script fail nice and fast if any command fails or a required argument is missing.
set -euo pipefail

#----------------------------------------DEAD CODE--------------------------------------
#JD - The interactive prompt below is no longer needed because RDAI now writes the password to a temporary file.
# read -p "Enter password for hotspot: " hotspot_password
#JD - The old direct command below is no longer needed because the password is now read from the file.
# nmcli device wifi hotspot ifname wlan0 ssid Hotspot4 password $hotspot_password

#---------------------------------------NETWORK CONFIG-------------------------------

#JD - This path points to the temporary password file created before reboot.
password_file="$1"
#JD - This path points to the one-shot cron file that should be removed after the helper runs.
cleanup_cron_file="$2"

#JD - This reads the hotspot password from the temporary file without preserving line breaks.
hotspot_password="$(tr -d '\r\n' < "$password_file")"

#JD- removing the one-shot cron file and the temporary password file before permanent changes happen.
rm -f "$cleanup_cron_file" "$password_file"

#JD-This command creates the hotspot connection using the password that RDAI stored previously.
nmcli device wifi hotspot ifname wlan0 ssid Hotspot4 password "$hotspot_password"

#JD - This makes the hotspot start automatically from now on whenever the device is booted.
nmcli connection modify id Hotspot connection.autoconnect yes

#JD - This gives the hotspot special autoconnect priority.
nmcli connection modify id Hotspot connection.autoconnect-priority 1

#JD - This reboots so the new NetworkManager settings take effect.
reboot
