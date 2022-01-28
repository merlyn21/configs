#!/bin/bash

name_db="scheduler_service"

docker run --rm --network=stend_default -e PGPASSWORD=postgres postgres:12 psql -h psql -U postgres -l
docker run --rm --network=stend_default -v "$(pwd):/root/build" -e PGPASSWORD=postgres postgres:12 psql -h psql -U postgres -c "create database $name_db;"
docker run --rm --network=stend_default -v "$(pwd):/root/build" -e PGPASSWORD=postgres postgres:12 psql -h psql -U postgres -d $name_db -f /root/build/schema-postgres.sql
docker run --rm --network=stend_default -e PGPASSWORD=postgres postgres:12 psql -h psql -U postgres -l
