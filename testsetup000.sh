#!/bin/bash

# # Manual Config:
#    # setup tplink network adapter:
#    apt install -y network-manager net-tools
#    vim /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf
#       ORIGINAL
#          [keyfile]
#          unmanaged-devices=*,except:type:wifi,except:type:gsm,except:type:cdma
#       MODIFIED
#          [keyfile]
#          unmanaged-devices=*,except:type:ethernet,except:type:gsm,except:type:cdma
#    # disable wifi:
#    manual/etc/network/interfaces iface wlan0 inet 
#       iface wlan0 inet 
#    systemctl restart NetworkManager
#    #Disable Wait For Online 
#      systemctl disable systemd-networkd-wait-online.service
#      systemctl mask systemd-networkd-wait-online.service
#    #Ignore Laptop Lid Closing
#    sudo gedit /etc/systemd/logind.conf 
#       HandleLidSwitch=ignore
#       LidSwitchIgnoreInhibited=no
TIMECTL
   

# Must be ran as root using:
#     cd && git clone https://github.com/YetAnotherGeorge/ubuntu-media-serv-00 && cd ubuntu-media-serv-00 && bash testsetup000.sh
#
#     => Folder structure (INPUT):
#     ~/bash-public
#        RegisterColors.sh             #bash
#        IHRC.BashConfig.001.sh        #bash
#        IHRC.SSH.001.conf             #SSH
#        IHRC.Nginx-RTMP.001.conf      #Nginx-RTMP (using port 1935)
#        IHRC.smb.003.conf             #Samba
#        IHRC.qbittorrent.001.service  #qbittorent
#        
#        testsetup000.sh
#
#     ======================================================================================
#     /ihrcdata      -> drwxr-xr-x  4  root     root
#        /backup     -> drwxrws---  2  IHRCsmb  IHRCsmb
#        /media      -> drwxrws---  2  IHRCsmb  IHRCsmb
#           /Seagate -> drwxrws---  2  IHRCsmb  IHRCsmb
#     ======================================================================================
#     qbittorent:
#        App Data:   /home/qbittorrent-user
#        Downloads:  /ihrcdata/media/Seagate/seedbox
#     ======================================================================================
#     jellyfin:
#        App Data:   /home/jellfin-user
#        Media:      /ihrcdata/media/
#     ======================================================================================
#=====================[Install Config]=====================
#       SSH Port          :    
# user  root     password : 
# user  NONROOT  password : 
# user  IHRCsmb password  : IHRCsmb
# !qbittorrent-nox        : save path must be /ihrcdata/media/Seagate/seedbox
#==========================================================


set -e # exit when any command fails
IHRC_DIR=$PWD #save github pull dir in case it's ever changed
timedatectl set-timezone Europe/Bucharest

# Perform updates & install all required packages for the rest of the process
   apt purge samba* #in case old versions cause bugs although they probably can't 
   apt update && apt upgrade -y && mandb

   apt install -y              \
      vim                      \
      git curl                 \
      pwgen                    \
      tree                     \
      lshw                     \
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

   #ookla speedtest-cli install
   wget https://install.speedtest.net/app/cli/ookla-speedtest-1.1.1-linux-x86_64.tgz
   tar -xf ookla-speedtest-1.1.1-linux-x86_64.tgz
   cp speedtest /usr/bin
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
   ufw allow $SSH_PORT_NUMBER/tcp comment "SSH TCP Port"

   systemctl enable ssh --now
#
# Create media server file structure + users + group assignments + fstab
   useradd --system --shell /usr/sbin/nologin IHRCsmb
   printf "\nEnter IHRCsmb user's password: \n"
   passwd IHRCsmb
   printf "\nEnter IHRCsmb user's samba password (same as user password): \n"
   smbpasswd -a IHRCsmb

   mkdir --mode=750 /ihrcdata && cd /ihrcdata
   mkdir backup && mkdir media && mkdir media/Seagate 
   chmod -R 2750 * && chown -R IHRCsmb:IHRCsmb *

   printf "\n#LABEL=Seagate             /ihrcdata/media/Seagate     ext4     defaults          0        2\n" >> /etc/fstab
   printf "Manually Configure Seagate (must have label 'Sagate' in fstab, must be mounted on /ihrcdata/media/Seagate), then continue script execution...\n"
   read
#
# Samba
   cd $IHRC_DIR
   cp IHRC.smb.003.conf /etc/samba/smb.conf 
   testparm -s
   systemctl restart smbd
   ufw allow samba
#
# Configure qbittorrent (UI on port 8085)
   useradd --system --shell /usr/sbin/nologin --create-home qbittorrent-user
   usermod -G IHRCsmb qbittorrent-user

   mkdir --mode=2770 /ihrcdata/media/Seagate/seedbox
   chown qbittorrent-user:IHRCsmb /ihrcdata/media/Seagate/seedbox

   cd $IHRC_DIR
   cp IHRC.qbittorrent.001.service /etc/systemd/system/qbittorrent.service
   systemctl daemon-reload 
   systemctl enable qbittorrent
   systemctl start qbittorrent
   ufw allow 8085 comment "qbittorrent web UI"
#
# Configure NGINX-Rtmp on port 1935
   cd $IHRC_DIR
   systemctl disable nginx --now

   cp IHRC.Nginx-RTMP.001.conf /etc/nginx/nginx.conf
   nginx -t
   ufw allow 1935 comment "NGINX-RTMP"

   systemctl enable nginx --now
#
# Jellyfin Docker 
   useradd --system --shell /usr/sbin/nologin --create-home jellyfin-user
   usermod -G IHRCsmb jellyfin-user

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
      --mount type=bind,source=/ihrcdata/media,target=/media \
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
#