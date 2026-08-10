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
