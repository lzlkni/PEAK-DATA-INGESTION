#! /bin/bash

time_zone="/usr/share/zoneinfo/Asia/Hong_Kong"
echo "Changing time zone to: ${time_zone}" 
sudo rm /etc/localtime

sudo ln -s ${time_zone} /etc/localtime