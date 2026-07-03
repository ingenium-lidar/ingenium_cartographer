#!/bin/bash
#JD - This helper is launched by cron after reboot, so it is written to be run with bash.
#JD - This makes the helper fail nice and fast if any command fails or a required argument is missing.
set -euo pipefail
#JD - I love pointers FYI
# JD - This here variable points to the network configuration script that should run after reboot.
network_config_script="$1"
# JD - This var points to the temporary password file created before reboot
password_file="$2"
# JD - This var points to the one-shot cron file that must be removed before rerunning is possible
cron_file="$3"
#JD -This removes the reboot trigger before waiting so the cron job, having done its duty, cannot repeat.
rm -f "$cron_file"
#JD - This gives NetworkManager a hefty buffer to get up and going before the hotspot script runs.
sleep 15
#JD - This passes control over to the network configuration script.
exec /bin/bash "$network_config_script" "$password_file" "$cron_file"
