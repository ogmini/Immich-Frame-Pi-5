#!/bin/sh

echo +36000 | tee /sys/class/rtc/rtc0/wakelarm
shutdown -h now
