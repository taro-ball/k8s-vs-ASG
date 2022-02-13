#!/bin/bash
set -x
mydate=$(date +"%Y-%m-%d-%H-%M")
cc="sshpass -p ${SSHpass} scp -r $PWD ${SSHuser}@${SSHhost}:/home/${SSHuser}/$mydate"