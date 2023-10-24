project?=default
from?=default
db?=postgres

# -- Optional --
# overrides of the variables using a gitignored file
-include ./Makefile.env

# Shows information about the local configuration
info:
	@clear
	@echo "============================\n     Amazing Postgres \n============================\n"
	@echo "Current Project ... $(project)"
	@echo "Target DB ......... $(db)"
	@echo "Seed/Query ........ $(from)"
	@echo "\n"

# Sets an environmental file to apply a different project.
_project:
	@[ ! -f Makefile.env ] && echo "project=$(project)" > Makefile.env || echo ""
	@sed 's/$(project)/$(from)/g' Makefile.env > Makefile.env.tmp
	@rm -f Makefile.env && mv Makefile.env.tmp Makefile.env
project:
	@echo "Setting project from: $(project) to $(from)"
	@$(MAKE) -s -f Makefile _project

start:
	@echo "Starting Postgres with PGTap..."
	@docker build -t pgtap ./testing/unit-tests/pgtap
	@docker compose up -d

stop:
	@echo "Stopping Postgres..."
	@docker compose down

restart: stop start

clean:
	@echo "Stopping Postgres..."
	@docker compose down
	@docker run --rm -v $(PWD):/data alpine:3.16.0 rm -rf ./data/.docker-data

# Alias for applying the current project's migrations
init: up

psql:
	@echo "Connecting to the database ("quit" to exit) ..."
	@docker exec -it pg psql -U postgres postgres

logs:
	clear
	@echo "Attaching to Postgres logs..."
	@docker compose logs -f postgres




#
# Migrations
#

up: $(CURDIR)/projects/$(project)/src/*
	clear
	@echo "Running migrations UP"
	@for file in $(shell find $(CURDIR)/projects/$(project)/src/ -name 'up.sql' | sort ) ; do \
		echo "---> Apply:" $$(basename $$(dirname $$file))/$$(basename $$file); \
		docker exec -i pg psql -U postgres postgres < $${file}; \
	done

down: $(CURDIR)/projects/$(project)/src/*
	clear
	@echo "Running migrations DOWN"
	@for file in $(shell find $(CURDIR)/projects/$(project)/src/ -name 'down.sql' | sort -r ) ; do \
		echo "---> Apply:" $$(basename $$(dirname $$file))/$$(basename $$file); \
		docker exec -i pg psql -U postgres postgres < $${file};	\
	done

reset:
	clear
	@echo "Reset Database Schema ..."
	@docker exec -i pg psql -U postgres template1 -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'postgres' AND pid <> pg_backend_pid();"
	@docker exec -i pg psql -U postgres template1 -c 'DROP DATABASE IF EXISTS "$(db)";'
	@docker exec -i pg psql -U postgres template1 -c 'CREATE DATABASE "$(db)";'

init: up seed
rebuild: reset init

#
# Unit Tests
#

test.reset:
	clear
	@echo "Reset Database Schema ..."
	@docker exec -i pg psql -U postgres template1 -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'test-db' AND pid <> pg_backend_pid();"
	@docker exec -i pg psql -U postgres template1 -c 'DROP DATABASE IF EXISTS "test-db";'
	@docker exec -i pg psql -U postgres template1 -c 'CREATE DATABASE "test-db";'

test.up: $(CURDIR)/projects/$(project)/src/*
	@for file in $(shell find $(CURDIR)/projects/$(project)/src/ -name 'up.sql' | sort ) ; do \
		echo "---> Apply:" $$(basename $$(dirname $$file))/$$(basename $$file); \
		docker exec -i pg psql -U postgres test-db < $${file}; \
	done

test.init: test.reset test.up

run:
	clear
	@echo "Running Unit Tests ..."
	@docker run --rm \
		--network=$(shell basename $(CURDIR))_default \
		--name pgtap \
		-v $(CURDIR)/projects/$(project)/tests/:/t \
		pgtap \
    	-h postgres -u postgres -w postgres -d test-db -t '/t/*.sql'

test: test.init run


#
# Utils
#

.PHONY: seed
seed:
	@docker exec -i pg psql -U postgres $(db) < projects/$(project)/seed/$(from).sql

query:
	@docker exec -i pg psql -U postgres $(db) < projects/$(project)/sql/$(from).sql

# https://www.postgresql.org/docs/current/pgbench.html
env?="F=F"
numClients?=5
numThreads?=10
numTransactions?=10
bench:
	@clear
	@echo "\n# Running PgBench to:\n> db=$(db); query=$(project)/sql/$(project).sql\n"
	@docker run --rm \
		-e $(env) \
		-e PGPASSWORD=postgres \
		-v $(CURDIR)/projects/$(project)/sql:/sql:ro \
		--network=$(shell basename $(CURDIR))_default \
		postgres:16 \
		pgbench -h postgres -p 5432 -U postgres -d $(db) \
			-c $(numClients) -j $(numThreads) -t $(numTransactions) \
			-f /sql/$(from).sql