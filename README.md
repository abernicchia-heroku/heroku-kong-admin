# Kong Admin API on Heroku

This repository contains a Dockerized "Kong Gateway Admin API (Control Plane) configured to run on Heroku. Kong is a popular, open-source API Gateway that helps you manage, secure, and monitor your APIs.

## Disclaimer

The author of this article makes any warranties about the completeness, reliability and accuracy of this information. **Any action you take upon the information of this website is strictly at your own risk**, and the author will not be liable for any losses and damages in connection with the use of the website and the information provided. **None of the items included in this repository form a part of the Heroku Services.**

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Prerequisites

- Heroku CLI installed
- Docker installed (for local development)
- A Heroku account
- PostgreSQL add-on attached to your Heroku app

## Deployment Steps

1. Create a new Heroku app:
   ```bash
   heroku create your-app-name
   ```

2. Add PostgreSQL add-on:
   ```bash
   heroku addons:create heroku-postgresql:standard-0
   ```

3. Deploy the application:
   ```bash
   git push heroku main
   ```

## Database Setup

Kong requires database migrations to be run before it can start serving requests. This setup handles migrations in two ways:

### Option 1: Automatic Migrations (Recommended for First Deploy)

When deploying for the first time, the `APP_RUN_KONG_MIGRATIONS` environment variable is automatically set to `true` in app.json. This will:
- Run the necessary database migrations during the first startup
- Create all required database tables
- Initialize the schema

After the first successful deployment, you should disable automatic migrations:
```bash
heroku config:set APP_RUN_KONG_MIGRATIONS=false -a your-app-name
```

### Option 2: Manual Migrations (For Updates)

For subsequent Kong version updates or if you prefer manual control, you can run migrations using a one-off dyno:

1. First, ensure automatic migrations are disabled:
   ```bash
   heroku config:set APP_RUN_KONG_MIGRATIONS=false -a your-app-name
   ```

2. Run migrations manually:
   ```bash
   heroku run bash -a your-app-name
   ```

3. Once inside the dyno's shell, the bootstrap script will automatically configure the database connection, and you can run:
   ```bash
   kong migrations bootstrap --force
   ```

## Verification

After running the migrations, you can verify that Kong is running properly by checking the logs:

```bash
heroku logs --tail
```

You should see messages indicating that Kong has started successfully and is listening for requests.

## Configuration

The Kong gateway is configured using the following files:
- `kong.conf`: Main configuration file
- `kong.yml.sample`: Sample of declarative configuration for routes and services
- `Dockerfile`: Container configuration and bootstrap script

Environment variables are automatically configured by the bootstrap script using the `DATABASE_URL` provided by Heroku.

## Troubleshooting

If you encounter any issues:

1. Check the logs:
   ```bash
   heroku logs --tail
   ```

2. Verify the database connection:
   ```bash
   heroku config | grep DATABASE_URL
   ```

3. If needed, you can restart the application:
   ```bash
   heroku restart
   ```

## Local Development

To build and run the container locally:

1. Build the image:
   ```bash
   docker build -t kong-heroku .
   ```

2. Run the container:
   ```bash
   docker run -p 8000:8000 -e DATABASE_URL=your_postgres_url kong-heroku
   ```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Support

For issues and questions, please open an issue in the GitHub repository.

## Managing Kong Configuration with decK

[decK](https://docs.konghq.com/deck/) is Kong's official configuration management tool. It allows you to manage Kong's configuration as code and sync it with your Kong instance.

### Prerequisites

1. Install decK:
   ```bash
   # macOS
   brew install kong/deck/deck

   # Linux
   curl -sL https://github.com/kong/deck/releases/latest/download/deck_$(uname -s)_amd64.tar.gz | tar xz -C /tmp/
   sudo mv /tmp/deck /usr/local/bin/
   ```

### Initial Setup

1. Start the Heroku Admin API app

4. In a new terminal, create a configuration file:
   ```bash
   # Get the dyno's URL (replace your-app-name)
   MYKONG_ADMIN_API_URL=$(heroku info -a <your-app-name> | grep "Web URL" | awk '{print $3}')
   
   # Export current configuration
   deck gateway dump --kong-addr $MYKONG_ADMIN_API_URL --output-file kong.yaml
   ```

### Managing Configuration

1. Edit `kong.yaml` to define your services, routes, plugins, and other Kong entities:
   ```yaml
   _format_version: "3.0"
   services:
     - name: example-service
       url: http://example.com
       routes:
         - name: example-route
           paths:
             - /example
       plugins:
         - name: rate-limiting
           config:
             minute: 5
   ```

2. Validate your configuration:
   ```bash
   deck file validate kong.yaml
   ```

3. Diff changes before applying:
   ```bash
   deck gateway diff --kong-addr $MYKONG_ADMIN_API_URL kong.yaml
   ```

4. Apply the configuration:
   ```bash
   deck gateway sync --kong-addr $MYKONG_ADMIN_API_URL kong.yaml
   ```

5. Test the example-service
   ```bash
   MYKONG_PROXY_URL=$(heroku info -a <your-kong-proxy-app-name> | grep "Web URL" | awk '{print $3}')
   
   curl $MYKONG_PROXY_URL/example
   ```


### Best Practices

1. Version Control:
   - Keep your `kong.yaml` in version control
   - Review changes through pull requests
   - Use CI/CD to validate configuration files

2. Environment Management:
   - Use separate configuration files for different environments
   - Use decK's `--select-tag` to manage environment-specific configurations

3. Security:
   - Never commit sensitive values (use environment variables)
   - Limit Admin API access to trusted networks
   - Always run Admin API in one-off dynos, never in production

4. Backup:
   - Regularly export your configuration using `deck dump`
   - Store backups in a secure location

### Troubleshooting

If you encounter issues:

1. Verify connectivity:
   ```bash
   curl $MYKONG_ADMIN_API_URL/status
   ```

2. Check decK version compatibility:
   ```bash
   deck version
   ```

3. Enable verbose logging:
   ```bash
   deck gateway sync --kong-addr $MYKONG_ADMIN_API_URL --verbose 1 kong.yaml
   ```
