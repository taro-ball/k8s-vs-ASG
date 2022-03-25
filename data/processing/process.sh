#!/bin/bash

# 1.1 generate csv from AWS json
find ./$1* -maxdepth 0 -type d -exec ./csv_gen.sh {} \;

# 1.2 generate cobined fortio json
find ./$1* -maxdepth 0 -type d -exec ./fortio_prc.sh {} \;

# 2.1 plot fortio data
fg="python ../k8s-aws-thesis/data/processing/foldergraph.py --overwrite"
find ./$1*/csv -maxdepth 0 -type d -exec $fg {} \; -exec $fg --metric cpuUtilization {} \; -exec $fg --metric groupInServiceCapacity {} \;

# 2.2 plot csv data
find ./$1*/csv/*.csv -exec python ../k8s-aws-thesis/data/processing/simplegraph.py {} \;

