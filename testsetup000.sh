#!/bin/bash

# Must be ran as root using:
#     cd && git clone https://github.com/YetAnotherGeorge/ubuntu-media-serv-00 && cd ubuntu-media-serv-00
#     chmod 744 testsetup000.sh && ./testsetup000.sh
#
#     => Folder structure (INPUT):
#     ~/bash-public
#        RegisterColors.sh
#        IHRC.BashConfig.001.sh
#        
#        IHRC.SSH.001.conf
#        IHRC.Nginx-RTMP.001.conf #using port 1935
#        IHRC.smb.001.conf
#        IHRC.qbittorrent.001.service
#        
#        testsetup000.sh
#
#     ======================================================================================
#     /home
#        /ihrcdata      -> drwxr-xr-x  4  ihrcdata ihrcdata
#           /backup     -> drwxrws---  2  ihrc-bak ihrc-bak
#           /media      -> drwxrws---  2  ihrc-med ihrc-med
#              /Seagate -> drwxrws---  2  ihrc-med ihrc-med
#     ======================================================================================
#     qbittorent:
#        App Data:   /home/qbittorrent-user
#        Downloads:  /home/ihrcdata/media/Seagate/seedbox
#     ======================================================================================
#     jellyfin:
#        App Data:   /home/jellfin-user
#        Media:      /home/ihrcdata/media/
#     ======================================================================================
#=====================[Extra Config]=====================
#     SSH Port          :          
#     ihrc-bak password : 
#     ihrc-med password : 
# !qbittorrent-nox      : save path must be /home/ihrcdata/media/Seagate/seedbox
#========================================================


set -e # exit when any command fails
IHRC_DIR=$PWD #save github pull dir in case it's ever changed

# Perform updates & install all required packages for the rest of the process
   apt update && apt upgrade -y && mandb

   apt install -y              \
      vim                      \
      git curl                 \
      pwgen                    \
      tree                     \
      `#SERVERS`               \
      openssh-server           \
      nginx libnginx-mod-rtmp  \
      samba                    \
      qbittorrent-nox          \
      gnupg ca-certificates lsb-release `#for docker (curl above)`

      #docker install
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      echo \
         "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
         $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      apt update
      apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
#
# Bash Startup:
   cd $IHRC_DIR
   cp RegisterColors.sh /etc/profile.d/
   cp IHRC.BashConfig.001.sh /etc/profile.d/
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
   cp IHRC.SSH.001.conf /etc/ssh/sshd_config.d/
   printf "Setting selected port number in /etc/ssh/sshd_config.d/IHRC.SSH.001.conf: \n"
   sed --in-place --regexp-extended "s/\\\$SSH_PORT_NUMBER/$SSH_PORT_NUMBER/gm" /etc/ssh/sshd_config.d/IHRC.SSH.001.conf
   grep --perl-regexp "^\s*Port" /etc/ssh/sshd_config.d/IHRC.SSH.001.conf
   printf "\n"

   #change firewall rules
   ufw deny 22/tcp
   ufw allow $SSH_PORT_NUMBER/tcp comment "SSH TCP Port"

   systemctl enable ssh --now
#
# Configure NGINX-Rtmp on port 1935
   cd $IHRC_DIR
   systemctl disable nginx --now

   cp IHRC.Nginx-RTMP.001.conf /etc/nginx/nginx.conf
   nginx -t
   ufw allow 1935 comment "NGINX-RTMP"

   systemctl enable nginx --now
#
# Create media server file structure + users + group assignments + fstab
   useradd --system --shell /usr/sbin/nologin ihrc-bak
   useradd --system --shell /usr/sbin/nologin ihrc-med

   cd /home
   mkdir --mode=755 ihrcdata && cd ihrcdata

   mkdir --mode=2770 backup && chown ihrc-bak:ihrc-bak backup #2770 => d rwx rws --- 
   mkdir --mode=2770 media  && chown ihrc-med:ihrc-med media  #2770 => d rwx rws --- 
   mkdir --mode=2770 media/Seagate && chown ihrc-med:ihrc-med media/Seagate

   #set passwords for backup and media:
   printf "\nEnter ihrc-bak (backup) user's password: \n"
   passwd ihrc-bak
   printf "\nEnter ihrc-med (media)  user's password: \n"
   passwd ihrc-med
   printf "\n"

   printf "\n#LABEL=Seagate             /home/ihrcdata/media/Seagate     ext4     defaults          0        2\n" >> /etc/fstab
   printf "Manually Configure Seagate (must have label 'Sagate' in fstab, must be mounted on /home/ihrcdata/media/Seagate), then continue script execution...\n"
   read TMP_VARIABLE
#
# Samba 
   cd $IHRC_DIR
   cp IHRC.smb.001.conf /etc/samba/smb.conf 
   testparm
   systemctl restart smbd
   ufw allow samba
#
# Configure qbittorrent (UI on port 8085)
   useradd --system --shell /usr/sbin/nologin --create-home qbittorrent-user
   usermod -G ihrc-med qbittorrent-user

   mkdir --mode=2770 /home/ihrcdata/media/Seagate/seedbox
   chown qbittorrent-user:ihrc-med /home/ihrcdata/media/Seagate/seedbox

   cd $IHRC_DIR
   cp IHRC.qbittorrent.001.service /etc/systemd/system/qbittorrent.service
   systemctl daemon-reload 
   systemctl enable qbittorrent
   systemctl start qbittorrent
   ufw allow 8085 comment "qbittorrent web UI"
#
# Jellyfin Docker 
   useradd --system --shell /usr/sbin/nologin --create-home jellyfin-user
   usermod -G ihrc-med jellyfin-user

   mkdir --mode=750 /home/jellyfin-user/config /home/jellyfin-user/cache
   chown jellyfin-user:jellyfin-user /home/jellyfin-user/config /home/jellyfin-user/cache

   #get uid:gid
   JELLYFIN_USR_UID_GID=$( grep "jellyfin-user" /etc/passwd | cut --delimiter=":" --fields 3-4 )

   docker run -d                                   \
      --name jellyfin                              \
      --user $JELLYFIN_USR_UID_GID                 \
      --net=host                                   \
      --volume /home/jellyfin-user/config:/config  \
      --volume /home/jellyfin-user/cache:/cache    \
      --mount type=bind,source=/home/ihrcdata/media,target=/media \
      --restart=unless-stopped                     \
      jellyfin/jellyfin

   ufw allow 8096/tcp comment "jellyfin" 
   ufw allow 8920/tcp comment "jellyfin"
   ufw allow 1900/udp comment "jellyfin"
   ufw allow 7359/udp comment "jellyfin"
#
#print statuses
   cd $IHRC_DIR

   printf "\n" >> testsetup000.statuslog.log
   systemctl status ssh >> testsetup000.statuslog.log
   printf "\n" >> testsetup000.statuslog.log
   systemctl status nginx >> testsetup000.statuslog.log
   printf "\n" >> testsetup000.statuslog.log
   systemctl status smbd >> testsetup000.statuslog.log
   printf "\n" >> testsetup000.statuslog.log
   systemctl status qbittorrent >> testsetup000.statuslog.log

   printf "\n" >> testsetup000.statuslog.log
   ufw status  >> testsetup000.statuslog.log

   vim testsetup000.statuslog.log
