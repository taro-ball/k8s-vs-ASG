#!/bin/bash
# time equals t*24h (should be negative)
# only works for directories without subfolders
t=$1
if  [ -z "$1" ]; then
echo 'no t specified, setting t to -1 (last 24 hours)'
t=-1
fi

last_backups=$(ssh robyn@gcloud "find /home/parasail/* -maxdepth 0 -ctime $t -type d")
echo remote: $last_backups === local: | xargs -n1
find ./*  -maxdepth 0 -ctime $t -type d 
read -p "Press enter to start"
for folder in $(echo $last_backups); do
    f=${folder##*/}
    if [ ! -d "./$f" ]
    then
        echo ==== copying $folder ====
        #rsync -av robyn@gcloud:$folder .
        scp -r robyn@gcloud:$folder .
    else
        echo ==== skipping $folder as already exists ====
    fi
done