#!/bin/bash

FAN="/sys/class/hwmon/hwmon0/pwm1"
CPU=$(cat /sys/class/thermal/thermal_zone0/temp)
MINTEMP="40"
MINPWM="25"

while true ; do
  FANSPEED=$(cat $FAN)
  CPUTEMP=$(($CPU/1000))
  echo "FAN=$FANSPEED, CPUTEMP=${CPUTEMP}C"
  if [[ "$FANSPEED" -lt "$MINPWM" ]]; then
    cat $MINPWN > $FAN
  fi
  sleep 5
done