#!/bin/sh

RAILS_HOME="/path/to/nventory"

USAGE="Usage: $0 -start <#days.ago> -stop <#days.ago>  ** If not specified, start or stop will default to value of 1"

while [ $# -gt 0 ]
do
    case "$1" in
        -start)  start=$2; shift;;
	-stop)  stop=$2; shift;;
        *) echo $USAGE; exit 1;;
    esac
    shift
done

if [ ! $start ]; then start=1 ;fi
if [ ! $stop ]; then stop=1 ;fi
if [ $stop -gt $start ]; then 
  echo "!!! # of days ago greater than # of days ago to start !!!"
  exit 1
fi

echo "START: $start"
echo "STOP: $stop"

cd $RAILS_HOME
script/runner -e production "UtilizationMetricsByNodeGroupsController.new.process_node_group_metrics($stop,$start)"
script/runner -e production "UtilizationMetricsGlobalController.new.process_global_metrics($stop,$start)"
