#!/bin/sh
set -e

parse_database_url() {
    echo "Parsing DATABASE_URL ..."
    # Extract each component using cut and sed
    userpass=$(echo "$DATABASE_URL" | sed -e "s|postgres://\([^@]*\)@.*|\1|")
    hostport=$(echo "$DATABASE_URL" | sed -e "s|postgres://[^@]*@\([^/]*\)/.*|\1|")
    dbname=$(echo "$DATABASE_URL" | sed -e "s|postgres://[^@]*@[^/]*/\(.*\)|\1|")
    
    # Split userpass into username and password
    export KONG_PG_USER=$(echo "$userpass" | cut -d: -f1)
    export KONG_PG_PASSWORD=$(echo "$userpass" | cut -d: -f2)
    
    # Split hostport into host and port
    export KONG_PG_HOST=$(echo "$hostport" | cut -d: -f1)
    export KONG_PG_PORT=$(echo "$hostport" | cut -d: -f2)
    
    # Set database name
    export KONG_PG_DATABASE="$dbname"
    
    # Debug output
    echo "Parsed database configuration:"
    echo "KONG_PG_USER=$KONG_PG_USER"
    echo "KONG_PG_PASSWORD=<redacted>"
    echo "KONG_PG_HOST=$KONG_PG_HOST"
    echo "KONG_PG_PORT=$KONG_PG_PORT"
    echo "KONG_PG_DATABASE=$KONG_PG_DATABASE"
}

setup_kong() {
    # Ensure PORT is set and configure admin listening
    if [ -z "$PORT" ]; then
        echo "Error: PORT environment variable is not set"
        exit 1
    fi
    export KONG_ADMIN_LISTEN="0.0.0.0:$PORT"
    echo "Configured Kong Admin API to listen on: $KONG_ADMIN_LISTEN"
}

run_migrations() {
    echo "Running database migrations..."
    kong migrations bootstrap --force
    if [ $? -eq 0 ]; then
        echo "Migrations completed successfully"
    else
        echo "Error: Failed to run migrations"
        exit 1
    fi
}

if [ -n "$DATABASE_URL" ]; then
    echo "DATABASE_URL is set, attempting to parse..."
    parse_database_url
    
    # Verify all required variables are set
    if [ -z "$KONG_PG_USER" ] || [ -z "$KONG_PG_PASSWORD" ] || \
       [ -z "$KONG_PG_HOST" ] || [ -z "$KONG_PG_PORT" ] || \
       [ -z "$KONG_PG_DATABASE" ]; then
        echo "Error: Failed to parse one or more database connection parameters"
        echo "Please ensure DATABASE_URL is in the format: postgres://user:password@host:port/dbname"
        exit 1
    fi
    
    setup_kong
    echo "Successfully configured Kong"

    # Run migrations if APP_RUN_KONG_MIGRATIONS is set to true
    if [ "$APP_RUN_KONG_MIGRATIONS" = "true" ]; then
        run_migrations
    fi
else
    echo "Error: DATABASE_URL not set"
    exit 1
fi

# Execute the original entrypoint script
exec /docker-entrypoint.sh "$@" 