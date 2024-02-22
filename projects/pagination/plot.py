import pandas as pd
import matplotlib.pyplot as plt

# Load the dataset
df = pd.read_csv('log.csv', header=None)

# Define column names for convenience
df.columns = ['series_name', 'ignore1', 'ignore2', 'ignore3', 'pagination_depth', 'tps']

# Extract the series name without path and extension
df['series_name'] = df['series_name'].apply(lambda x: x.split('/')[-1].split('.')[0])

# Convert pagination_depth to numeric value (assuming it's always prefixed with 'amount=' or 'page=')
df['pagination_depth'] = df['pagination_depth'].apply(lambda x: int(x.split('=')[-1]))

# Normalize offset pagination value
df.loc[df['series_name'] == 'offset', 'pagination_depth'] *= 10

#print(df)

# Plotting
fig, ax = plt.subplots()

# Group by series_name to plot each series separately
for name, group in df.groupby('series_name'):
    ax.plot(group['pagination_depth'], group['tps'], marker='o', label=name)

ax.set_xlabel('Pagination Depth')
ax.set_ylabel('TPS')
ax.set_title('TPS by Pagination Depth for Different Series')
ax.legend()

plt.show()
