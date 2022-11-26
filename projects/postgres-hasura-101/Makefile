# HASURA SEED SOURCE
# it is used in the
from?=dummy

# HASURA MIGRATION STEPS
# it is used in the hasura postgres migration scripts to control
# how many up/down migrations to applu
steps?=1

# HASURA PROJECT
# it lets you change the source code for your Hasura meta-files
project?=cqrs



#
# Project Management
#

start:
	@echo "Starting the project..."
	@docker-compose up -d
	@docker-compose logs -f

stop:
	@echo "Stopping the project..."
	@docker-compose down

logs:
	@docker-compose logs -f

clear: stop
	@echo "Destroy local data..."
	@sudo rm -rf .docker-data

restart: stop start
reset: stop clear start

install-cli:
	@curl -L https://github.com/hasura/graphql-engine/raw/stable/cli/get.sh | bash



#
# Hasura State Management
#

init:
	@echo "Applying migrations to all databases..."
	@hasura migrate apply --project $(project) --all-databases
	@echo "Applying Hasura metadata..."
	@hasura metadata apply --project $(project)
	@echo "Seeding the main database from: \"$(from).sql\"..."
	@hasura seed apply --project $(project) --database-name default --file $(from).sql

seed:
	@echo "Seeding the main database from: \"$(from).sql\"..."
	@hasura seed apply --project $(project) --database-name default --file $(from).sql


#
# PostgreSQL Migration Utilities
#

migrate-init:
	@hasura init $(project) --endpoint http://localhost:8080 --admin-secret hasura

migrate:
	@hasura migrate apply --project $(project) --database-name default
	
migrate-status:
	@hasura migrate status --project $(project) --database-name default

migrate-up:
	@hasura migrate apply --project $(project) --database-name default --up $(steps)

migrate-down:
	@hasura migrate apply --project $(project) --database-name default --down $(steps)

migrate-redo:
	@hasura migrate apply --project $(project) --database-name default --down $(steps)
	@hasura migrate apply --project $(project) --database-name default --up $(steps)

migrate-create:
	@hasura migrate create \
		"$(name)" \
		--up-sql "SELECT NOW();" \
		--down-sql "SELECT NOW();" \
		--database-name default \
		--project $(project)
