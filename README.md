# Immich-Frame-Pi-5

Instructions for how I setup a digital picture frame for my parents. 

Requirements:
* Immich - [https://immich.app/](https://immich.app/)
* Immich Kiosk - [https://github.com/damongolding/immich-kiosk](https://github.com/damongolding/immich-kiosk)
* Tailscale
* Raspberry Pi OS (13 Trixie)
* Raspberry Pi 5 (1GB)
* 10" Raspberry Pi Touch 2 Display - [https://www.raspberrypi.com/products/touch-display-2/](https://www.raspberrypi.com/products/touch-display-2/)
* 3D Printed Frame - [https://makerworld.com/en/models/3116241-raspberry-pi-10-1-touch-display-2-case#profileId-3514731](https://makerworld.com/en/models/3116241-raspberry-pi-10-1-touch-display-2-case#profileId-3514731)

I leave the installation/setup of Immich and Immich Kiosk to their documentation. This article specifically talks about the setup of the frame with the goal of being able to have a hands-off digital picture frame that can live at my parent's house that has minimal reliance on cloud vendors. Immich allows me to host my own photos and Tailscale gives me the ability to remotely manage and connect the frame. Using Tailscale, I do not need to expose Immich to the public.

Assemble the pieces...

Install Raspberry Pi OS (13 Trixie) on the card.

Update the eeprom. [https://github.com/raspberrypi/rpi-eeprom](https://github.com/raspberrypi/rpi-eeprom)
```
sudo rpi-eeprom-update -a
```

Install Firefox via the Add/Remove Software. Feel free to use the browser of your choice. I found that Firefox in kiosk mode worked the best for me. I was encountering issues using Chromium related to unclean shutdowns and recovering tabs.

## start_firefox.sh
This script will start Firefox in kiosk mode and load the URL to Immich Kiosk.

Create file
```
nano start_firefox.sh
```
Add contents
```
#!/bin/sh

firefox --kiosk immich:3000
```

## autostart
This sets the start_firefox.sh script to execute when the desktop environment loads.

Edit autostart
```
nano ~/.config/labwc/autostart
```
Add contents
```
/path/to/start_firefox.sh
```

## monitor-off.sh
This script will set the wakealarm for an appropriate time and shutdown the Raspberry Pi 5. There is no reason to have this running all night when people are asleep. More details about the wakealarm/rtc can be found at [https://homelabwiki.xyz/using-the-rtc-on-raspberry-pi-5/](https://homelabwiki.xyz/using-the-rtc-on-raspberry-pi-5/).

Create file
```
nano monitor-off.sh
```

Add contents
```
#!/bin/sh

# Wake up 10 hours after shutdown
echo +36000 | tee /sys/class/rtc/rtc0/wakealarm
shutdown -h now
```

## Setup systemd timer 
We need to setup a systemd timer and service to shutdown the Raspberry Pi 5. A good writeup for this can be found at [https://www.fosslinux.com/48317/scheduling-tasks-systemd-timers-linux.htm](https://www.fosslinux.com/48317/scheduling-tasks-systemd-timers-linux.htm)

Create file
```
sudo nano /etc/systemd/system/monitor-off.service
```

Add contents
```
[Unit]
Description=Daily Monitor Off

[Service]
Type=oneshot
ExecStart=/path/to/monitor-off.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=mutli-user.target
```

Create file
```
sudo nano /etc/systemd/system/monitor-off.timer
```

Add contents
```
[Unit]
Description=Run Monitor Off Daily
RefuseManualStart=yes
RefuseManualStop=no

[Timer]
OnCalendar=*-*-* 22:00:00
Persistent=false

[Install]
WantedBy=timers.target
```

Enable and Start Timer
```
sudo systemctl daemon-reload
sudo systemctl enable --now monitor-off.timer
```

Check status
```
sudo systemctl list-timers
```
