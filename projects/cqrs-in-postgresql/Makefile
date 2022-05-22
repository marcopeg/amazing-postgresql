# Local Variables
# ===============
#
# Pass custom values to the `make` cli as:
# > make start pg_name=foobar
#
pg_name?=test-db
pg_password?=postgres
pg_version?=13.2
pg_data?=.docker-data
pg_seed?=seed.sql
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
		postgres:$(pg_version)
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
		   $(CURDIR)/src/schema_v2.sql \
		   $(CURDIR)/src/schema_v3.sql \
		   $(CURDIR)/src/schema_v4.sql \
		   $(CURDIR)/src/schema_v5.sql \
		   $(CURDIR)/src/schema_v6.sql \
		   $(CURDIR)/src/schema_v7.sql \
		   $(CURDIR)/src/schema_v8.sql \
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
	@docker exec -i $(pg_name) psql -U postgres test-db < ./seed/${pg_seed}

seed-only:
	@clear
	@docker exec -i $(pg_name) psql -U postgres test-db < ./seed/${pg_seed}


stress: reset
	clear
	@echo "Stressing Project ..."
	@mkdir -p $(CURDIR)/$(pg_data)
	@cat $(CURDIR)/seed/seed_v7.sql \
		   $(CURDIR)/seed/seed_v8.sql \
	> $(CURDIR)/$(pg_data)/init-schema.sql
	@docker exec -i $(pg_name) psql -U postgres test-db < $(CURDIR)/$(pg_data)/init-schema.sql