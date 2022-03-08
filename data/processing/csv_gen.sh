#!/bin/bash
#set -x

if [ -z "$1" ]; then
    echo no target directory specified
    echo please specify a directory or run over all subdirectories by running:
    echo find "./2022.03*" -maxdepth 1 -type d -exec ./csv_gen.sh {} \\\;
    # echo 'find -path "./2022.03*" -prune -type d | xargs -L 1 ./csv_gen.sh' (this one ignores ctrl+c)
    exit
fi
tdir=$1

if cd $tdir; then
    echo processing $PWD
else
    echo invalid target dir - exit; exit
fi
sleep 1
if mkdir csv; then
    echo writing to $PWD/csv
else
    echo csv already exists - exit; exit
fi

for f in *_data.json
do
    count=`cat $f | egrep \"Id\" | wc -l`
    for((y=0;y<=$(( $count - 1 ));y+=1));
    do
        echo metric $y in $f
        metric=`jq --raw-output '.MetricDataResults['${y}'] |.Id' ${f}`
        jq --raw-output '.MetricDataResults['${y}'] |["datetime",.Id],([.Timestamps, .Values] | transpose[])| @csv' ${f} > ./csv/metric_${metric}.csv
        #${y}_${f%.*}.csv
    done
done