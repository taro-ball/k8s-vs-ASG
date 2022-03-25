#!/bin/bash
start=2022-03-14
#end=now
# range example: find . -type d -newermt "2022-03-18" \! -newermt "2022-03-19"
find . -maxdepth 1 -type d -newermt "$start" > .tmp_list

tests="k8s_apache k8s_taewa asg_apache asg_taewa"

for val in $tests; do
    echo =======$val
    grep $val .tmp_list | wc -l
    grep $val .tmp_list
done

