import pandas as pd
import numpy as np
import argparse
import pathlib

parser = argparse.ArgumentParser()
parser.add_argument("file_path", type=pathlib.Path)
parser.add_argument("--overwrite", help="overwrite destination",
                    action="store_true")

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
if out_file.exists() and not p.overwrite:
  print("Output already exists. Skip.")
  quit()

df = pd.read_csv(file, parse_dates=['datetime'], index_col="datetime")
df2=df.resample('60S').mean() # show gaps, see https://stackoverflow.com/questions/38572534/pandas-plot-time-series-with-minimized-gaps

#ydata = df2.iloc[:, 0]
#print(ydata.max())
#tks=np.arange(0, ydata.max(), round(ydata.max()/20))

plot = df2.plot(kind='line', style='.-', linewidth=1.0, grid=1, figsize=(7,3.5)) #yticks=tks
plot.legend(loc='center left', bbox_to_anchor=(0.0, 0.1))
title=f'Run id: {p.file_path.parent.parent.name}'
plot.set_title(title, y=1.11, pad=-14,fontsize=10)
fig = plot.get_figure()
fig.savefig(out_file, bbox_inches='tight')