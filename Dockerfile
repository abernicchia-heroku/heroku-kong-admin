FROM kong:3.9

# Create directory for declarative config
RUN mkdir -p /usr/local/kong/declarative

# Copy configuration files
COPY kong.conf /etc/kong/kong.conf
COPY kong.yaml /usr/local/kong/declarative/kong.yaml

# Copy and set up bootstrap script
USER root
COPY kong-heroku-bootstrap.sh /kong-heroku-bootstrap.sh
RUN chmod +x /kong-heroku-bootstrap.sh

# Set environment variables
ENV KONG_DATABASE=postgres \
    KONG_PG_SSL=on \
    KONG_PG_SSL_VERIFY=off \
    KONG_PROXY_ACCESS_LOG=/dev/stdout \
    KONG_ADMIN_ACCESS_LOG=/dev/stdout \
    KONG_PROXY_ERROR_LOG=/dev/stderr \
    KONG_ADMIN_ERROR_LOG=/dev/stderr \
    KONG_PROXY_LISTEN=off \
    KONG_ADMIN_LISTEN=0.0.0.0:8001 \
    PORT=8001

# Expose port (default, will be overridden by Heroku)
EXPOSE ${PORT}

# Use our bootstrap script as entrypoint
ENTRYPOINT ["/kong-heroku-bootstrap.sh"]

# Start kong
CMD ["kong", "docker-start"] 