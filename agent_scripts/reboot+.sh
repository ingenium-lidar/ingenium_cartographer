#!/bin/bash

#AB This script is fundamentally based on code written by JD at ingenium_cartographer, commit 6fa076b5625ede44d97a891df0abd1bfbf18f88b

post_reboot_script="$(realpath "$1")"
post_reboot_cron_file="/etc/cron.d/reboot_plus_cronjob" #JD/AB - This stores the one-shot cron file that will make the the post-reboot script run just one time.
helper_script="$HOME/.reboot+_helper.sh"
args_for_next_script=("${@:2}")
log_file="/var/log/reboot+$(date +%s).log"
printf -v quoted_args '%q ' "${args_for_next_script[@]}"

#AB Create a blank helper script that the cron job will run after reboot and mark it as executable
touch "$helper_script"
chmod +x "$helper_script"

#JD - This gets rid of any previous cron file before writing the new one.
sudo rm -f "$post_reboot_cron_file"

#JD/AB - This writes the one-shot cron entry that will invoke the post-reboot script
echo "@reboot root /bin/bash $helper_script" > "$log_file" 2>&1 | sudo tee "$post_reboot_cron_file" > /dev/null #AB This whole pipe/tee/redirect to /dev/null thing is so that we can write with sudo (you can't do `sudo >`)

#JD - This sets the cron file permissions to the mode required by cron.d.
sudo chmod 644 "$post_reboot_cron_file"

#AB - To that helper script, add the following code:
cat << EOF > "$helper_script"
#!/bin/bash

#AB This file was created by reboot+.sh, an agent script in ingenium_cartographer. It will delete itself after your next reboot. 

#AB Delete the reboot+ helper script and the cron file that booted it
rm -f "$helper_script"
rm -f "$post_reboot_cron_file"

#AB Run the post-reboot script with all other args appended
"$post_reboot_script" $quoted_args >> /var/log/reboot+.log 2>&1

EOF

echo "reboot+ has completed successfully, and $post_reboot_script will run upon reboot!"

#AB Reboot immediately unless the user cancels. If the user cancels, the script passed to reboot+ will run after the next reboot. 
echo "The system will now reboot! Press any key to cancel..."
sleep 1
echo "Rebooting in..."


reboot_cancelled=0
for i in {5..1} #AB count down 5, 4, 3, 2, 1...
do
  echo "$i"
  
  # Check if a key was pressed
  if read -t 1 -n 1; then
    echo ""
    echo "Reboot cancelled."
    reboot_cancelled=1
    break
  fi
done

# Reboot if not cancelled
if [ $reboot_cancelled -eq 0 ]; then
  echo "Rebooting now!"
  sudo reboot
fi
