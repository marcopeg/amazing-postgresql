start:
	@docker compose up -d

stop:
	@docker compose down

clean: stop
	@docker run --rm -v $(PWD):/data alpine:3.16.0 rm -rf ./data/.docker-data

init: up
up: $(CURDIR)/migrations/*
	@for file in $(shell find $(CURDIR)/migrations/ -name 'up.sql' | sort ) ; do \
		echo "---> Apply:" $$(basename $$(dirname $$file))/$$(basename $$file); \
		docker exec -i pg psql -U postgres postgres < $${file}; \
	done

down: $(CURDIR)/migrations/*
	@for file in $(shell find $(CURDIR)/migrations/ -name 'down.sql' | sort -r ) ; do \
		echo "---> Apply:" $$(basename $$(dirname $$file))/$$(basename $$file); \
		docker exec -i pg psql -U postgres postgres < $${file};	\
	done

reset:
	docker exec -it pg psql -U postgres postgres -c 'DROP SCHEMA IF EXISTS public CASCADE;'
	docker exec -it pg psql -U postgres postgres -c 'CREATE SCHEMA IF NOT EXISTS public;'

rebuild: down up