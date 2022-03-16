#!/bin/bash
#set -x

if [ -z "$1" ]; then
    echo no target directory specified
    echo please specify a directory or run over all subdirectories by running:
    echo find "./2022.03*" -maxdepth 0 -type d -exec ./csv_gen.sh {} \\\;
    # echo 'find -path "./2022.03*" -prune -type d | xargs -L 1 ./csv_gen.sh' (this one ignores ctrl+c)
    exit
fi
tdir=$1

if cd $tdir; then
    name=`basename $PWD`
    echo processing $name
else
    echo invalid target dir - exit; exit
fi

spath="./csv/$name.json"
if test -f $spath; then
    echo "$spath exists, skip."
    exit
fi

mkdir csv
#rm -fv $spath
for f in 2022*.json
do
  jq --compact-output '{"Labels":.Labels,"StartTime": .StartTime,"ActualQPS":.ActualQPS,"ActualDuration":.ActualDuration,"NumThreads":.NumThreads,"URL":.URL,"DurationHistogram.Avg":.DurationHistogram.Avg,"DurationHistogram.Count":.DurationHistogram.Count,"200count":.RetCodes["200"],"Sizes.Avg":.Sizes.Avg,"HeaderSizes.Avg":.HeaderSizes.Avg}' ${f} >> ./csv/$name.json
done
