#! /bin/bash
POSTGRES_SCRIPT='DROP TABLE IF EXISTS my_table;'

docker-compose run --rm azurite-bootstrap az storage container delete -n test
docker-compose run -e PGPASSWORD=password123 --rm postgresql psql --host=postgresql --username=my_user -c "$POSTGRES_SCRIPT" my_database
