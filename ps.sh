#!/bin/bash


CpuUsage () {
  stat=$(cat /proc/$1/stat)
  stat=${stat/\(*\)/}
  statValues=( $(echo $stat | awk '{print $6, $13, $14, $15, $16}') )

  ttyNr=${statValues[0]}
  uTime=${statValues[1]}
  sTime=${statValues[2]}
  cuTime=${statValues[3]}
  csTime=${statValues[4]}

  let "ttyMinor = ttyNr & 255"
  let "ttyMajor = (ttyNr & 255)/256"

  if [ "$ttyMinor" -eq 0 ]
  then 
    ttyNum="?"
  else
    ttyNum="tty$ttyMinor"
  fi

  hertz=$(getconf CLK_TCK)
  let "totalTime = (uTime + sTime + cuTime + csTime)/hertz"
  let "procMinutes = totalTime / 60"
  let "procSeconds = totalTime - procMinutes * 60"
}

# занесем в массив все процесссы
array=( $(ls /proc | grep "^[0-9]\+$" | sort -n) )
# определим прошедшее время в секундах после запуска системы 
#upTime="$( cat /proc/uptime | awk -F'[.]' '{print $1}')"
#statValues="$( cat /proc/32672/stat | awk '{print $14,$15,$16,$17,$22}')"

(echo "  PID TTY      STAT   TIME COMMAND"
for i in ${array[@]}
do
  if [ -f /proc/$i/stat ]
  then
    CpuUsage $i
    echo $i $ttyNum $(cat /proc/$i/status | awk '/State/{print $2}') $procMinutes:$(printf "%02d " $procSeconds) $(cat /proc/$i/status | awk '/Name/{print $2}')
  fi
done) | column -t


# функция чуть-чуть работает :-(
    function my_ps
    {
        pid_array=`ls /proc | grep -E '^[0-9]+$'`
        clock_ticks=$(getconf CLK_TCK)
        total_memory=$( grep -Po '(?<=MemTotal:\s{8})(\d+)' /proc/meminfo )

        cat /dev/null > .data.ps

        for pid in $pid_array
        do
            if [ -r /proc/$pid/stat ]
            then
                stat_array=( `sed -E 's/(\([^\s)]+)\s([^)]+\))/\1_\2/g' /proc/$pid/stat` )
                uptime_array=( `cat /proc/uptime` )
                statm_array=( `cat /proc/$pid/statm` )
                comm=( `grep -Po '^[^\s\/]+' /proc/$pid/comm` )
                user_id=$( grep -Po '(?<=Uid:\s)(\d+)' /proc/$pid/status )

                user=$( id -nu $user_id )
                uptime=${uptime_array[0]}

                state=${stat_array[2]}
                ppid=${stat_array[3]}
                priority=${stat_array[17]}
                nice=${stat_array[18]}

                utime=${stat_array[13]}
                stime=${stat_array[14]}
                cutime=${stat_array[15]}
                cstime=${stat_array[16]}
                num_threads=${stat_array[19]}
                starttime=${stat_array[21]}

                total_time=$(( $utime + $stime ))
                #add $cstime - CPU time spent in user and kernel code ( can olso add $cutime - CPU time spent in user code )
                total_time=$(( $total_time + $cstime ))
                seconds=$( awk 'BEGIN {print ( '$uptime' - ('$starttime' / '$clock_ticks') )}' )
                cpu_usage=$( awk 'BEGIN {print ( 100 * (('$total_time' / '$clock_ticks') / '$seconds') )}' )

                resident=${statm_array[1]}
                data_and_stack=${statm_array[5]}
                memory_usage=$( awk 'BEGIN {print( (('$resident' + '$data_and_stack' ) * 100) / '$total_memory'  )}' )

                printf "%-6d %-6d %-10s %-4d %-5d %-4s %-4u %-7.2f %-7.2f %-18s\n" $pid $ppid $user $priority $nice $state $num_threads $memory_usage $cpu_usage $comm >> .data.ps

            fi
        done

        clear
        printf "\e[30;107m%-6s %-6s %-10s %-4s %-3s %-6s %-4s %-7s %-7s %-18s\e[0m\n" "PID" "PPID" "USER" "PR" "NI" "STATE" "THR" "%MEM" "%CPU" "COMMAND"
        sort -nr -k9 .data.ps | head -$1
        read_options
    }

