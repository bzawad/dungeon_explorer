#!/usr/bin/env bash

# Exit on error
set -e

# Get app name
APP_NAME="$(<app_name.txt)"

# SQL to drop all tables
SQL="DO \$\$ DECLARE
  r RECORD;
BEGIN
  FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = current_schema()) LOOP
    EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
  END LOOP;
END \$\$;"

# Execute the SQL
echo "Dropping all tables..."
echo "$SQL" | gigalixir pg:psql -a "${APP_NAME}"

# Run migrations
echo "Running migrations..."
gigalixir run -a "${APP_NAME}" mix ecto.migrate

# Run seeds
echo "Running seeds..."
gigalixir run -a "${APP_NAME}" mix run priv/repo/seeds.exs

echo "Database reset complete!" 