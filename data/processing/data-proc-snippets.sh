# the following is done in the runs directory

# 0. sync
./gsync

# 1.1 generate csv from json
find ./2022.03* -maxdepth 0 -type d -exec ./csv_gen.sh {} \;

# 1.2 generate fortio json
find ./2022.03.12* -maxdepth 0 -type d -exec ./fortio_prc.sh {} \;

# 2. plot csv data
find ./2022.03.11*/csv/*.csv -exec python ../k8s-aws-thesis/data/processing/simplegraph.py {} \;
find ./2022.03*/csv/*.csv -exec python /c/full/path/simplegraph.py --overwrite {} \;

