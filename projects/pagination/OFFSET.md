./bench.sh -t 1000 -f sql/sql1/offset-combined.sql -p page=100
./bench.sh -t 1000 -f sql/sql1/cursor-or.sql -p amount=0
./bench.sh -t 1000 -f sql/sql1/cursor-union.sql -p amount=0

1, 3452
10, 2667
100, 926
250, 447
500, 224

0, 2703
25, 373
