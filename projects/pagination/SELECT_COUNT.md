# Select Count

```prompt
You are an expert in drawing svg charts based on dataset that are provided in csv format.

Here is a dataset that contains the results from 2 different tests.
each test refer to the same sql file.
the last colum contains TPS (transaction per second)
the second last column contains the X value

title of the chart: Select Count Performance
title of X axis: pagination depth

the no-index a light red
the with-cursor a solid green

create the line chart as svg

sql/select-count/select-no-index.sql,1,1,1,amount=100000,88
sql/select-count/select-no-index.sql,1,1,1,amount=100000,51
sql/select-count/select-no-index.sql,1,1,1,amount=100000,37
sql/select-count/select-no-index.sql,1,1,1,amount=100000,51
sql/select-count/select-no-index.sql,1,1,1,amount=100000,44
sql/select-count/select-no-index.sql,1,1,1,amount=100000,34
sql/select-count/select-no-index.sql,1,1,1,amount=100000,24
sql/select-count/select-no-index.sql,1,1,1,amount=100000,27
sql/select-count/select-no-index.sql,1,1,1,amount=100000,22
sql/select-count/select-no-index.sql,1,1,1,amount=100000,24
sql/select-count/select-with-index.sql,1,1,1,amount=100000,219
sql/select-count/select-with-index.sql,1,1,1,amount=100000,229
sql/select-count/select-with-index.sql,1,1,1,amount=100000,191
sql/select-count/select-with-index.sql,1,1,1,amount=100000,148
sql/select-count/select-with-index.sql,1,1,1,amount=100000,89
sql/select-count/select-with-index.sql,1,1,1,amount=100000,96
sql/select-count/select-with-index.sql,1,1,1,amount=100000,82
sql/select-count/select-with-index.sql,1,1,1,amount=100000,554
sql/select-count/select-with-index.sql,1,1,1,amount=100000,277
sql/select-count/select-with-index.sql,1,1,1,amount=100000,238

```
