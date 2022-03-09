import sys
import pandas as pd

arg = sys.argv[1]
print(arg)

file='C:/Users/pa/OneDrive/7.UniCode/0thesis-code/myjupy/1stTry/asg_data_cpu_normal.csv'

df = pd.read_csv(file, parse_dates=['date'], index_col="date")
#df.plot()

plot = df.plot()
fig = plot.get_figure()
fig.savefig("output.png")