#!/bin/bash
# copy from gcloud permanent 
t=-0.4
last_backups=$(ssh robyn@gcloud "find /home/parasail/* -ctime $t -type d")
echo $last_backups
find . -ctime $t -type d
sleep 999
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