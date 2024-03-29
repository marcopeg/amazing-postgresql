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

stop:
	@echo "Stopping Postgres..."
	@docker stop $(pg_name) || true

clear: stop
	@echo "Dropping the project..."
	sudo rm -rf $(CURDIR)/$(pg_data)

psql:
	@echo "Connecting to the database ("quit" to exit) ..."
	@docker exec -it $(pg_name) psql -U postgres test-db

logs:
	clear
	@echo "Attaching to Postgres logs..."
	@docker container logs -f $(pg_name)

schema:
	@clear
	@echo "Building Project ..."
	@mkdir -p $(CURDIR)/$(pg_data)
	@cat $(CURDIR)/src/schema_v1.sql \
		   $(CURDIR)/src/schema_v2.sql \
		   $(CURDIR)/src/schema_v3.sql \
		   $(CURDIR)/src/schema_v4.sql \
			 $(CURDIR)/src/append.sql \
	> $(CURDIR)/$(pg_data)/init-schema.sql


destroy:
	@clear
	@echo "Destroying current db..."
	@docker exec -i $(pg_name) psql -U postgres < ../../testing/unit-tests/reset-db.sql

reset: destroy schema
	@clear
	@echo "Applying db schema..."
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
	@docker exec -i $(pg_name) psql -U postgres test-db < ./seed.sql

seed-only:
	@clear
	@docker exec -i $(pg_name) psql -U postgres test-db < ./seed.sql


stress: stop schema
	@touch .env
	@rm -rf $(CURDIR)/$(pg_data)/pg
	@docker-compose up -d postgres
	@docker-compose up --scale producer=${scale} producer
	@docker-compose up consumer