#!/bin/bash

#AB Make the ssh config directory
mkdir -p $HOME/.ssh
#AB create the ssh config file
touch $HOME/.ssh/config

#AB Add a config block that suppresses warnings for lidar@10.42.0.1 and disables strict host key checking.
#   This is fine from a security point of view in this case because we only ever access the rpi via the 
#   wifi network that it itself generates, which is password-protected, so MITM attacks are not a concern here. 
cat >> ~/.ssh/config <<'EOF'
Host 10.42.0.1
    User lidar
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR

Host 10.42.0.1
    User ubuntu
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF

#AB restrict edit permissions (SSH requires this, apparently)
chmod 600 $HOME/.ssh/config
