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

init:
	@echo "Initializing the project state..."
	hasura migrate apply --all-databases --project hasura-ecomm
	hasura metadata apply --project hasura-ecomm
	hasura seed apply --database-name default --project hasura-ecomm