#!/bin/bash
start=2022-03-16
end=now
# range example: find . -type d -newermt "2022-03-18" \! -newermt "2022-03-19"
find . -maxdepth 1 -type d -newermt "$start" > .tmp_list

tests="k8s_taewa_3lite_ asg_taewa_3lite_ k8s_apache_3_ k8s_taewa_3_ asg_apache_3_ asg_taewa_3_"

# Iterate the string variable using for loop
for val in $tests; do
    echo =======$val
    grep $val .tmp_list | wc -l
    grep $val .tmp_list
done

