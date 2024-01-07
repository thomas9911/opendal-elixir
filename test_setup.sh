#! /bin/bash

POSTGRES_SCRIPT='CREATE TABLE IF NOT EXISTS my_table ( id serial PRIMARY KEY, key VARCHAR ( 128 ) UNIQUE NOT NULL, value bytea NOT NULL );'

docker-compose run --rm azurite-bootstrap az storage container create -n test
docker-compose run -e PGPASSWORD=password123 --rm postgresql psql --host=postgresql --username=my_user -c "$POSTGRES_SCRIPT" my_database
