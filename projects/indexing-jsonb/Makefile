from?=default
db?=postgres

start:
	@echo "Starting Postgres with PGTap..."
	@docker build -t pgtap ../../testing/unit-tests/pgtap
	@docker compose up -d

stop:
	@echo "Stopping Postgres..."
	@docker compose down

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

up: $(CURDIR)/src/*
	clear
	@echo "Running migrations UP"
	@for file in $(shell find $(CURDIR)/src/ -name 'up.sql' | sort ) ; do \
		echo "---> Apply:" $$(basename $$(dirname $$file))/$$(basename $$file); \
		docker exec -i pg psql -U postgres postgres < $${file}; \
	done

down: $(CURDIR)/src/*
	clear
	@echo "Running migrations DOWN"
	@for file in $(shell find $(CURDIR)/src/ -name 'down.sql' | sort -r ) ; do \
		echo "---> Apply:" $$(basename $$(dirname $$file))/$$(basename $$file); \
		docker exec -i pg psql -U postgres postgres < $${file};	\
	done

rebuild: reset up

reset:
	clear
	@echo "Reset Database Schema ..."
	@docker exec -i pg psql -U postgres template1 -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'postgres' AND pid <> pg_backend_pid();"
	@docker exec -i pg psql -U postgres template1 -c 'DROP DATABASE IF EXISTS "postgres";'
	@docker exec -i pg psql -U postgres template1 -c 'CREATE DATABASE "postgres";'


#
# Unit Tests
#

test.reset:
	clear
	@echo "Reset Database Schema ..."
	@docker exec -i pg psql -U postgres template1 -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'test-db' AND pid <> pg_backend_pid();"
	@docker exec -i pg psql -U postgres template1 -c 'DROP DATABASE IF EXISTS "test-db";'
	@docker exec -i pg psql -U postgres template1 -c 'CREATE DATABASE "test-db";'

test.schema: $(CURDIR)/src/*
	@for file in $(shell find $(CURDIR)/src/ -name 'up.sql' | sort ) ; do \
		echo "---> Apply:" $$(basename $$(dirname $$file))/$$(basename $$file); \
		docker exec -i pg psql -U postgres test-db < $${file}; \
	done

test.init: test.reset test.schema

run:
	clear
	@echo "Running Unit Tests ..."
	@docker run --rm \
		--network=$(shell basename $(CURDIR))_default \
		--name pgtap \
		-v $(CURDIR)/tests/:/t \
		pgtap \
    	-h postgres -u postgres -w postgres -d test-db -t '/t/*.sql'

test: test.init run


#
# Utils
#

.PHONY: seed
seed:
	@docker exec -i pg psql -U postgres $(db) < seed/$(from).sql

query:
	@docker exec -i pg psql -U postgres $(db) < sql/$(from).sql
