#!/bin/bash

cat <<EOF >/docker-entrypoint-initdb.d/init.sql
CREATE USER IF NOT EXISTS traqing WITH PASSWORD '${POSTGRES_PASSWORD_TRAQING}';

CREATE DATABASE IF NOT EXISTS traqing;
GRANT ALL PRIVILEGES ON DATABASE traqing TO traqing;
EOF

psql -U postgres -f /docker-entrypoint-initdb.d/init.sql
