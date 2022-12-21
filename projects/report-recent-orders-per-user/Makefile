# Local Variables
# ===============
#
# Pass custom values to the `make` cli as:
# > make start pg_name=foobar
#
pg_name?=test-db
pg_password?=postgres
pg_version?=15
pg_data?=.docker-data
file?=default
scale?=1


start:
	@echo "Starting Postgres..."
	@mkdir -p $(CURDIR)/$(pg_data)
	@touch .env
	@docker build -t pgtap ../../testing/unit-tests/pgtap
	@docker run --rm -d \
		--name $(pg_name) \
		-p 5432:5432 \
		-e POSTGRES_PASSWORD=postgres \
		-v $(CURDIR)/$(pg_data)/pg:/var/lib/postgresql/data \
		--cpus="2" \
		--memory="500m" \
		--memory-swap="1g" \
		--kernel-memory="500m" \
		postgres:$(pg_version) -c log_min_messages=INFO
	@docker logs -f $(pg_name)

stop:
	@echo "Stopping Postgres..."
	@docker stop $(pg_name) || true

clear: stop
	@echo "Destroy local data..."
	@rm -rf .docker-data

psql:
	@echo "Connecting to the database ("quit" to exit) ..."
	@docker exec -it $(pg_name) psql -U postgres test-db

logs:
	clear
	@echo "Attaching to Postgres logs..."
	@docker container logs -f $(pg_name)

schema:
	clear
	@echo "Building Project ..."
	@mkdir -p $(CURDIR)/$(pg_data)
	@cat $(CURDIR)/src/schema_v1.sql \
	> $(CURDIR)/$(pg_data)/init-schema.sql

reset: schema
	clear
	@docker exec -i $(pg_name) psql -U postgres < ../../testing/unit-tests/reset-db.sql
	@docker exec -i $(pg_name) psql -U postgres test-db < $(CURDIR)/$(pg_data)/init-schema.sql

test-only:
	clear
	@echo "Running Unit Tests ..."
	@docker run --rm \
		--name pgtap \
		--link $(pg_name):db \
		-v $(CURDIR)/tests/:/t \
		pgtap \
    	-h db -u postgres -w $(pg_password) -d test-db -t '/t/*.sql'

test: reset test-only
	
seed: reset
	@docker exec -i $(pg_name) psql -U postgres test-db < ./seed/${file}.sql

seed-only:
	@clear
	@docker exec -i $(pg_name) psql -U postgres test-db < ./seed/${file}.sql

run:
	@docker exec -i $(pg_name) psql -U postgres test-db < ./query/${file}.sql

stress: reset
	clear
	@echo "Stressing Project ..."
	@mkdir -p $(CURDIR)/$(pg_data)
	@cat $(CURDIR)/seed/seed_v7.sql \
		   $(CURDIR)/seed/seed_v8.sql \
	> $(CURDIR)/$(pg_data)/init-schema.sql
	@docker exec -i $(pg_name) psql -U postgres test-db < $(CURDIR)/$(pg_data)/init-schema.sql