#!/bin/bash

docker run --rm -v "$(pwd):/root/build" -e PGPASSWORD=postgres postgres:12 psql -h psql -U postgres db -f /root/build/scheduler_service.sql
