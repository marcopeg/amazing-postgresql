fast:
	@docker volume create pgdata 1>/dev/null
	@docker stop pg 2>/dev/null || true
	@docker rm pg 2>/dev/null || true
	@docker run -d --rm \
		--name pg \
		-e POSTGRES_PASSWORD=postgres \
		-v pgdata:/var/lib/postgresql/data \
		-v ./sql:/sql \
		-p 5432:5432 \
		postgres

stop:
	@docker stop pg 2>/dev/null || true
	@docker rm pg 2>/dev/null || true

down: stop
	@docker volume rm pgdata 2>/dev/null || true

slow:
	@docker volume create pgdata 1>/dev/null
	@docker stop pg 2>/dev/null || true
	@docker rm pg 2>/dev/null || true
	@docker run -d --rm \
		--name pg \
		-e POSTGRES_PASSWORD=postgres \
		-v pgdata:/var/lib/postgresql/data \
		-v ./sql:/sql \
		-p 5432:5432 \
		--memory="256m" \
		--cpus="0.5" \
		postgres \
		-c shared_buffers=64MB \
		-c work_mem=1MB \
		-c maintenance_work_mem=64MB \
		-c max_connections=100

init:
	./run.sh sql/sql1/_schema.sql
	./run.sh sql/sql1/_seed.sql
	./run.sh sql/sql1/_index.sql

test.clear:
	@rm -rf log.csv

test.offset:
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/offset.sql -p page=1
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/offset.sql -p page=10
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/offset.sql -p page=25
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/offset.sql -p page=50
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/offset.sql -p page=75
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/offset.sql -p page=100
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/offset.sql -p page=150
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/offset.sql -p page=200
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/offset.sql -p page=250
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/offset.sql -p page=300
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/offset.sql -p page=350

test.cursor.or:
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-or.sql -p page=1
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-or.sql -p page=10
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-or.sql -p page=25
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-or.sql -p page=50
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-or.sql -p page=75
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-or.sql -p page=100
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-or.sql -p page=150
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-or.sql -p page=200
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-or.sql -p page=250
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-or.sql -p page=300
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-or.sql -p page=350

test.cursor.union:
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-union.sql -p page=1
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-union.sql -p page=10
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-union.sql -p page=25
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-union.sql -p page=50
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-union.sql -p page=75
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-union.sql -p page=100
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-union.sql -p page=150
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-union.sql -p page=200
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-union.sql -p page=250
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-union.sql -p page=300
	./bench.sh -t 100 -l log.csv -f ./sql/sql1/cursor-union.sql -p page=350

test: test.clear test.offset test.cursor.or test.cursor.union