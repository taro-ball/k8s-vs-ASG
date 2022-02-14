#!/bin/bash
set -x
mydate=$(date +"%Y.%m.%d_%H-%M")
cc="sshpass -p ${SSHpass} scp -r $PWD ${SSHuser}@${SSHhost}:/home/${SSHuser}/$mydate"