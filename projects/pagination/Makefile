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