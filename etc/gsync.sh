#!/bin/bash
# time equals t*24h (should be negative)
t=$1
ssh_host=gcloud
if  [ -z "$1" ]; then
echo 'no t specified, setting t to -1 (last 24 hours)'
t=-1
fi

last_backups=$(ssh robyn@gcloud "find /home/parasail/* -maxdepth 0 -ctime $t -type d")
echo remote: $last_backups === local: | xargs -n1
find ./*  -maxdepth 0 -ctime $t -type d 
#read -p "Press enter to start sync"
echo ==== connecting to `ssh -G ${ssh_host} | grep hostname`
for folder in $(echo $last_backups); do
    f=${folder##*/}
    if [ ! -d "./$f" ]
    then
        echo
        echo ==== copying $folder ====
        #rsync -av robyn@gcloud:$folder .
        scp -r robyn@${ssh_host}:$folder .
    else
        echo ==== skipping $folder as already exists ====
    fi
done
echo ==== sync complete ====
ls -d */
