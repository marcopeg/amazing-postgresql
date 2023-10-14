# Local Variables
# ===============
#
# Pass custom values to the `make` cli as:
# > make start pg_name=foobar
#
pg_name?=test-db
pg_password?=postgres
pg_version?=16
pg_data?=.docker-data

start:
	@echo "Starting Postgres..."
	@docker build -t pgtap ./pgtap
	@docker run --rm -d \
		--name $(pg_name) \
		-p 5432:5432 \
		-e POSTGRES_PASSWORD=postgres \
		-v $(CURDIR)/$(pg_data):/var/lib/postgresql/data \
		postgres:$(pg_version)

stop:
	@echo "Stopping Postgres..."
	@docker stop $(pg_name) || true

psql:
	@echo "Connecting to the database ("quit" to exit) ..."
	@docker exec -it $(pg_name) psql -U postgres postgres

logs:
	clear
	@echo "Attaching to Postgres logs..."
	@docker container logs -f $(pg_name)

schema: $(CURDIR)/src/*
	@for file in $(shell find $(CURDIR)/src/ -name 'up.sql' | sort ) ; do \
		echo "---> Apply:" $$(basename $$(dirname $$file))/$$(basename $$file); \
		docker exec -i $(pg_name) psql -U postgres test-db < $${file}; \
	done

reset:
	clear
	@echo "Reset Database Schema ..."
	@docker exec -i $(pg_name) psql -U postgres < reset-db.sql

run:
	clear
	@echo "Running Unit Tests ..."
	@docker run --rm \
		--name pgtap \
		--link $(pg_name):db \
		-v $(CURDIR)/tests/:/t \
		pgtap \
    	-h db -u postgres -w $(pg_password) -d test-db -t '/t/*.sql'

test: reset schema run
	

