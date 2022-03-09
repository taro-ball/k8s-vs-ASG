import pandas as pd
import numpy as np
import argparse
import pathlib

parser = argparse.ArgumentParser()
parser.add_argument("file_path", type=pathlib.Path)

p = parser.parse_args()

if p.file_path.exists():
  #and type(p.file_path)
  print("processing ", p.file_path)
else:
  print("File does not exist. Exit.")
  quit()


file=p.file_path
#fileName=file.name
#dir=file.parent
out_file=file.with_suffix('.png')

df = pd.read_csv(file, parse_dates=['date'], index_col="date")
#df.plot()

plot = df.plot(kind='line',grid=1,figsize=(7,3.5),yticks=(np.arange(0, 100, 5)))
fig = plot.get_figure()
fig.savefig(out_file)