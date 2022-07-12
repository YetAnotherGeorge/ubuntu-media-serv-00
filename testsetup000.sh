#!/bin/bash

# Must be ran as root using:
#     cd && git clone https://github.com/YetAnotherGeorge/ubuntu-media-serv-00 && cd ubuntu-media-serv-00
#     chmod 744 testsetup000.sh && ./testsetup000.sh
#
#     => Folder structure (INPUT):
#     ~/bash-public
#        RegisterColors.sh
#        IHRC.BashConfig.sh
#
#        IHRC.SSH.conf
#        IHRC.Nginx-RTMP.conf #using port 1935
#        
#        testsetup000.sh
#
#     =======>
#     /home
#        /ihrcdata      -> drwxr-xr-x  4  ihrcdata  ihrcdata
#           /backup     -> drwxrws---  2   ihrc-bak ihrc-bak
#           /media      -> drwxrws---  2   ihrc-med ihrc-med
#              /Seagate



set -e # exit when any command fails
IHRC_DIR=$PWD #save github pull dir in case it's ever changed

# Perform updates & install all required packages for the rest of the process
   apt update && apt upgrade -y && mandb

   apt install -y              \
      git curl                 \
      pwgen                    \
      tree                     \
      `#SERVERS`               \
      openssh-server           \
      nginx libnginx-mod-rtmp  \
      docker                   \
      samba                    \
      qbittorrent-nox
#
# Bash Startup:
   cd $IHRC_DIR
   cp RegisterColors.sh /etc/profile.d/
   cp IHRC.BashConfig.sh /etc/profile.d/
#
# Enble firewall if not already active
ufw enable
#
# Configure SSH
   cd $IHRC_DIR
   systemctl disable ssh --now
   #ask for input
   printf "\nSpecify SSH port number: "
   read SSH_PORT_NUMBER
   printf "\n"

   #apply config
   cp IHRC.SSH.conf /etc/ssh/sshd_config.d/
   printf "Setting selected port number in /etc/ssh/sshd_config.d/IHRC.SSH.conf: \n"
   sed --in-place --regexp-extended "s/\\\$SSH_PORT_NUMBER/$SSH_PORT_NUMBER/gm" /etc/ssh/sshd_config.d/IHRC.SSH.conf
   grep --perl-regexp "^\s*Port" /etc/ssh/sshd_config.d/IHRC.SSH.conf
   printf "\n"

   #change firewall rules
   ufw deny 22/tcp
   ufw allow $SSH_PORT_NUMBER/tcp comment "SSH TCP Port"

   systemctl enable ssh --now
#
# Configure NGINX-Rtmp on port 1935
   cd $IHRC_DIR
   systemctl disable nginx --now

   cp IHRC.Nginx-RTMP.conf /etc/nginx/nginx.conf
   nginx -t
   ufw allow 1935

   systemctl enable nginx --now
#
# Create media server file structure + users + group assignments + fstab
   useradd --system --shell /usr/sbin/nologin ihrc-bak
   useradd --system --shell /usr/sbin/nologin ihrc-med

   mkdir --mode=755 ihrcdata && ch ihrcdata

   mkdir --mode=2770 backup && chown ihrc-bak backup && chgrp ihrc-bak backup #2770 => d rwx rws --- 
   mkdir --mode=2770 media  && chown ihrc-med media  && chgrp ihrc-med media  #2770 => d rwx rws --- 


   #set passwords for backup and media:
   printf "\nEnter ihrc-bak (backup) user's password: \n"
   passwd ihrc-bak
   printf "\nEnter ihrc-med (media)  user's password: \n"
   passwd ihrc-bak
   printf "\n"
#

# #qbittorrent web UI: port 8085
# cd $IHRC_DIR
# useradd --system --shell /usr/sbin/nologin --create-home qbittorrent-user
# cp IHRC.qbittorrent.service /etc/systemd/system/qbittorrent.service

# systemctl daemon-reload
# systemctl enable qbittorrent.service
# systemctl start qbittorrent.service
# ufw allow 8085


#print statuses
   printf "\n"
   ufw status
   printf "\n"
   systemctl status nginx
   printf "\n"
   systemctl status ssh
