#! /bin/bash
POSTGRES_SCRIPT='DROP TABLE IF EXISTS my_table;'

docker_compose_az() {
    docker-compose run --rm azurite-bootstrap az storage container delete -n test
}

plain_az() {
    az storage container delete -n test
}

docker_compose_ps() {
    docker-compose run -e PGPASSWORD=password123 --rm postgresql psql --host=postgresql --username=my_user -c "$POSTGRES_SCRIPT" my_database
}

plain_ps() {
    export PGPASSWORD=password123
    psql --host=postgresql --username=my_user -c "$POSTGRES_SCRIPT" my_database
}

docker_compose_az
docker_compose_ps
