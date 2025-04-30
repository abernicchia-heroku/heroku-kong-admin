FROM kong:3.5

# Copy configuration files
COPY kong.conf /etc/kong/kong.conf

# Create script to parse DATABASE_URL
RUN echo '#!/bin/sh\n\
if [ -n "$DATABASE_URL" ]; then\n\
  # Parse the DATABASE_URL\n\
  pattern="^postgres://([^:]+):([^@]+)@([^:]+):([^/]+)/(.+)$"\n\
  if echo "$DATABASE_URL" | grep -E "$pattern" > /dev/null; then\n\
    export KONG_PG_USER=$(echo "$DATABASE_URL" | sed -E "s/$pattern/\\1/")\n\
    export KONG_PG_PASSWORD=$(echo "$DATABASE_URL" | sed -E "s/$pattern/\\2/")\n\
    export KONG_PG_HOST=$(echo "$DATABASE_URL" | sed -E "s/$pattern/\\3/")\n\
    export KONG_PG_PORT=$(echo "$DATABASE_URL" | sed -E "s/$pattern/\\4/")\n\
    export KONG_PG_DATABASE=$(echo "$DATABASE_URL" | sed -E "s/$pattern/\\5/")\n\
    echo "Kong Postgres settings configured from DATABASE_URL"\n\
  else\n\
    echo "Error: DATABASE_URL format not recognized"\n\
    exit 1\n\
  fi\n\
else\n\
  echo "Error: DATABASE_URL not set"\n\
  exit 1\n\
fi\n\
\n\
# Execute the original entrypoint script\n\
exec /docker-entrypoint.sh "$@"' > /parse-db-url.sh && chmod +x /parse-db-url.sh

# Set environment variables
ENV KONG_PROXY_LISTEN=off \
    KONG_ADMIN_ACCESS_LOG=/dev/stdout \
    KONG_ADMIN_ERROR_LOG=/dev/stderr \
    KONG_ADMIN_GUI_AUTH=basic-auth \
    KONG_ENFORCE_RBAC=on \
    KONG_PG_SSL=on \
    KONG_PG_SSL_VERIFY=off \
    KONG_DATABASE=postgres

# Expose ports
EXPOSE 8001 8444

# Use our script as entrypoint
ENTRYPOINT ["/parse-db-url.sh"]

# Start kong
CMD ["kong", "docker-start"] 