# the following is done in the runs directory

# 0. sync
./gsync

# 1. generate csv from json
find ./2022.03* -maxdepth 0 -type d -exec ./csv_gen.sh {} \;

# 2. plot csv data
find ./2022.03*/csv/*.csv -exec python /c/full/path/simplegraph.py --overwrite {} \;