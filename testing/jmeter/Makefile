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

start:
	@echo "Starting Postgres..."
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

###
### Schema Utilities
###

drop-db:
	@docker exec -i $(pg_name) psql -U postgres < ./seeds/reset.sql

build-schema: $(CURDIR)/schema/*
	@for file in $(shell find $(CURDIR)/schema -name 'up.sql' | sort ) ; do \
		echo "---> Apply:" $${file}; \
		docker exec -i $(pg_name) psql -U postgres test-db < $${file};	\
	done

seed:
	@docker exec -i $(pg_name) psql -U postgres test-db < ./seeds/$(file).sql

test-init: drop-db build-schema

test: test-init
	jmeter -n \
		-t tests/$(file).jmx \
		-l results/$(file).csv \
		-j results/$(file).log

