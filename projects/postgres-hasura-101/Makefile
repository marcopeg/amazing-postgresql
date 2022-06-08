# HASURA SEED SOURCE
# it is used in the
seed?=dummy

# HASURA MIGRATION STEPS
# it is used in the hasura postgres migration scripts to control
# how many up/down migrations to applu
steps?=1



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



#
# Hasura State Management
#

init:
	@echo "Applying migrations to all databases..."
	@hasura migrate apply --project hasura-ecomm --all-databases
	@echo "Applying Hasura metadata..."
	@hasura metadata apply --project hasura-ecomm
	@echo "Seeding the main database from: \"$(seed).sql\"..."
	@hasura seed apply --project hasura-ecomm --database-name default --file $(seed).sql

seed:
	@echo "Seeding the main database from: \"$(seed).sql\"..."
	@hasura seed apply --project hasura-ecomm --database-name default --file $(seed).sql


#
# PostgreSQL Migration Utilities
#

migrate:
	@hasura migrate apply --project hasura-ecomm --database-name default
	
migrate-status:
	@hasura migrate status --project hasura-ecomm --database-name default


migrate-up:
	@hasura migrate apply --project hasura-ecomm --database-name default --up $(steps)

migrate-down:
	@hasura migrate apply --project hasura-ecomm --database-name default --down $(steps)

migrate-redo:
	@hasura migrate apply --project hasura-ecomm --database-name default --down $(steps)
	@hasura migrate apply --project hasura-ecomm --database-name default --up $(steps)

migrate-create:
	@hasura migrate create \
		"$(name)" \
		--up-sql "SELECT NOW();" \
		--down-sql "SELECT NOW();" \
		--database-name default \
		--project hasura-ecomm
	@hasura migrate apply --project hasura-ecomm --database-name default
