#!/bin/bash

docker run --rm --network=stend_default -e PGPASSWORD=postgres postgres:12 pg_dump -h postgres -U postgres -d scheduler_service > scheduler_service_.sql
