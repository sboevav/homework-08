#!/bin/bash

array=( $(ls /proc | grep "^[0-9]\+$" | sort -n) )

(echo "  PID TTY      STAT   TIME NAME COMMAND"
for i in ${array[@]}
do
#echo $i "1" "2" "3" ( $(cat /proc/1/status | awk '/Name/{print $2}') ) "5"
#echo $i "1" "2" "3" $(cat /proc/$i/status | awk '/Name/{print $2}')  $(cat /proc/$i/cmdline)

echo $i "1" "2" "3" $(cat /proc/$i/status | awk '/Name/{print $2}')  

done) | column -t 


