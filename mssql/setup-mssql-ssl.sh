#!/bin/bash

# setup-mssql-ssl.sh
# Script to set up MS SQL Server with SSL

# Create directories
mkdir -p certs data log secrets

# Generate SSL certificate
echo "Creating SSL certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout certs/mssql.key \
    -out certs/mssql.pem \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=MyCompany/CN=mssql-server"

# Set correct permissions
chmod 600 certs/mssql.key
chmod 644 certs/mssql.pem

echo "Certificates created:"
echo "- Private key: certs/mssql.key"
echo "- Certificate: certs/mssql.pem"

# Create .env file for SQL Server 2019
cat > .env << EOF
# MS SQL Server 2019 settings
SA_PASSWORD=YourStrongPassword123!
MSSQL_PID=Developer
ACCEPT_EULA=Y

# SSL settings for 2019
MSSQL_ENCRYPT_CONNECTIONS=1
EOF

echo ".env file created"

# Create an advanced docker-compose with SSL for SQL Server 2019
cat > docker-compose.ssl.yml << 'EOF'
version: '3.8'

services:
  mssql:
    image: mcr.microsoft.com/mssql/server:2019-latest
    container_name: mssql-ssl-2019
    hostname: mssql-server
    ports:
      - "1433:1433"
    environment:
      - ACCEPT_EULA=${ACCEPT_EULA}
      - SA_PASSWORD=${SA_PASSWORD}
      - MSSQL_PID=${MSSQL_PID}
      - MSSQL_ENCRYPT_CONNECTIONS=${MSSQL_ENCRYPT_CONNECTIONS}

    volumes:
      - ./certs:/var/opt/mssql/certs:ro
      - mssql_data:/var/opt/mssql/data
      - mssql_log:/var/opt/mssql/log
      - mssql_secrets:/var/opt/mssql/secrets

    # Initialization script with SSL setup for 2019
    entrypoint: >
      /bin/bash -c "
      # Wait for the filesystem to be ready
      sleep 5

      # Copy certificates to the working directory
      if [ -f /var/opt/mssql/certs/mssql.pem ]; then
        cp /var/opt/mssql/certs/mssql.pem /var/opt/mssql/data/mssql.pem
        cp /var/opt/mssql/certs/mssql.key /var/opt/mssql/data/mssql.key
        chown mssql:mssql /var/opt/mssql/data/mssql.*
        chmod 600 /var/opt/mssql/data/mssql.key
        chmod 644 /var/opt/mssql/data/mssql.pem

        # Configure SSL via mssql-conf for 2019
        /opt/mssql/bin/mssql-conf set network.forceencryption 1
        /opt/mssql/bin/mssql-conf set network.tlscert /var/opt/mssql/data/mssql.pem
        /opt/mssql/bin/mssql-conf set network.tlskey /var/opt/mssql/data/mssql.key
        /opt/mssql/bin/mssql-conf set network.tlsprotocols 1.2
      fi

      # Start SQL Server
      /opt/mssql/bin/sqlservr
      "

    healthcheck:
      test: >
        /opt/mssql-tools/bin/sqlcmd
        -S localhost -U sa -P \$$SA_PASSWORD
        -Q 'SELECT 1' -C
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 40s

volumes:
  mssql_data:
  mssql_log:
  mssql_secrets:
EOF

echo "docker-compose.ssl.yml created"

# Create a connection script with SSL for SQL Server 2019
cat > connect-ssl.sh << 'EOF'
#!/bin/bash

# Example connection to MS SQL Server 2019 with SSL
echo "Connecting to MS SQL Server 2019 with SSL..."

# Wait for the server to start
sleep 10

# Using sqlcmd with forced SSL
/opt/mssql-tools/bin/sqlcmd \
    -S localhost,1433 \
    -U sa \
    -P 'YourStrongPassword123!' \
    -C \
    -Q "SELECT @@VERSION, SERVERPROPERTY('IsIntegratedSecurityOnly')"

# Example connection strings for applications (SQL Server 2019):
echo ""
echo "Connection strings for SQL Server 2019:"
echo "ADO.NET: Server=localhost,1433;Database=master;User Id=sa;Password=YourStrongPassword123!;Encrypt=true;TrustServerCertificate=true;MultipleActiveResultSets=true;"
echo "JDBC: jdbc:sqlserver://localhost:1433;database=master;user=sa;password=YourStrongPassword123!;encrypt=true;trustServerCertificate=true;"
echo "ODBC: Driver={ODBC Driver 17 for SQL Server};Server=localhost,1433;Database=master;UID=sa;PWD=YourStrongPassword123!;Encrypt=yes;TrustServerCertificate=yes;"
EOF

chmod +x connect-ssl.sh setup-mssql-ssl.sh

echo ""
echo "Setup complete!"
echo ""
echo "To start:"
echo "1. ./setup-mssql-ssl.sh"
echo "2. docker-compose -f docker-compose.ssl.yml up -d"
echo "3. ./connect-ssl.sh (to test the connection)"
