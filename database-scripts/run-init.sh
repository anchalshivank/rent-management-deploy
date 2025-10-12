#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    # Use 'set -a' to export all variables
    set -a
    source .env
    set +a
else
    echo "Error: .env file not found!"
    exit 1
fi

# Test connection first
echo "Testing database connection..."
PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "SELECT 1;" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Failed to connect to database!"
    echo "Please check:"
    echo "  1. RDS security group allows your IP"
    echo "  2. RDS is publicly accessible"
    echo "  3. Password is correct"
    exit 1
fi

echo "✓ Connection successful!"
echo ""

# Run initialization
./init-all-databases.sh