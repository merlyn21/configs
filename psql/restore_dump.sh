#!/bin/bash

docker run --rm -v "$(pwd):/root/build" -e PGPASSWORD=postgres postgres:12 psql -h psql -U postgres db < /root/build/scheduler_service.sql
