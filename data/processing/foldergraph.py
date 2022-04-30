from tokenize import String
import pandas as pd
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("dir_path", type=Path)
parser.add_argument("--metric", type=str, default="estimatedProcessedBytes")
parser.add_argument("--threads", help="plot threads", action="store_true")
parser.add_argument("--overwrite", help="overwrite destination", action="store_true")


p = parser.parse_args()
aws_metric = p.metric #'estimatedProcessedBytes'#'cpuUtilization'

if p.dir_path.exists():
  #and type(p.file_path)
  print("processing ", p.dir_path)
else:
  print("Dir does not exist. Exit.")
  quit()

out_file=p.dir_path / ('QPS_'+aws_metric+'.png')
print("writing to "+ str(out_file))
if out_file.exists() and not p.overwrite:
  print("Output already exists. Skip.")
  quit()

csv_paths = p.dir_path.glob('**/*'+aws_metric+'.csv')
cpu_path=list(csv_paths)[0]
print("found: "+ str(cpu_path))

mdf = pd.read_csv(cpu_path, parse_dates=['datetime'], index_col="datetime")

json_paths = p.dir_path.glob('**/*.json')
fortio_path=list(json_paths)[0]
print("found: "+ str(fortio_path))

df = pd.read_json(fortio_path, lines=True)
df.rename(columns={"StartTime": "datetime"}, errors="raise", inplace = True)
#qps= df[["StartTime","ActualQPS"]]
df['datetime'] = pd.to_datetime(df['datetime']) # format='%Y%m%d%H%M%S'
df.set_index(['datetime'],inplace=True)

qps= df[["ActualQPS","NumThreads"]]
#qps.plot(kind="line",style='o') # df.plot(style=['+-','o-','.--','s:'])

import matplotlib.pyplot as plt
import matplotlib.dates as mdates

#define colors to use
hex1='#' # random color
for x in range(1,4):
    n=ord(aws_metric[x])-10
    n=n-100 if n%2==0 else n*2
    hex1+= f'{n:02X}'

col2 = 'red'


#define subplots
fig,ax0 = plt.subplots()


#add first line to plot
ax0.plot(qps.ActualQPS, color=col2, marker='s', linestyle='None', markersize = 6.0)
plt.grid()
# #add second y-axis label
ax0.set_ylabel('QPS', color=col2, fontsize=16)
ax0.set_ylim(ymin=0)
ax = ax0.twinx()


# #add second line to plot
line2 = ax.plot(mdf[aws_metric])


if aws_metric=="backendConnectionErrors":
  plt.setp(line2, color='purple', marker='o', linestyle='None', markersize = 6.0)
else:
  plt.setp(line2, color=hex1, marker='o', linewidth=1, markersize = 2.0)

#add y-axis label
ax.set_ylabel(aws_metric, color=hex1, fontsize=16)
ax.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))

if p.threads:
  # #define second y-axis that shares x-axis with current plot
  ax3 = ax0.twinx()
  ax3.spines.right.set_position(("axes", 1.2))
  # #add second line to plot
  ax3.plot(qps.NumThreads, color="purple", marker='o', linestyle='--', markersize = 5.0)

  # #add second y-axis label
  ax3.set_ylabel('threads', color="purple", fontsize=16)

fig.set_size_inches(7, 3.5)
fig.savefig(out_file, bbox_inches='tight', dpi=100)