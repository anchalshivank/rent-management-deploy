#!/bin/bash

# ============================================
# Initialize All Microservice Databases
# ============================================

set -e  # Exit on error

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Rent Microservices DB Initialization${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Host: ${DB_HOST}:${DB_PORT}${NC}"
echo -e "${BLUE}User: ${DB_USER}${NC}\n"

# Database names (singular naming convention)
declare -A DATABASES=(
    ["userdb"]="auth-service/schema.sql"
    ["propertydb"]="property-service/schema.sql"
    ["meterdb"]="iot-service/schema.sql"
    ["iotdb"]="meter-service/schema.sql"
    ["billingdb"]="billing-service/schema.sql"
)

# ============================================
# Step 1: Create databases if they don't exist
# ============================================
echo -e "${YELLOW}Step 1: Creating databases...${NC}"

for DB_NAME in "${!DATABASES[@]}"; do
    echo -e "  → Checking database: ${BLUE}${DB_NAME}${NC}"
    
    # Check if database exists
    DB_EXISTS=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -tAc \
        "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null || echo "")
    
    if [ "$DB_EXISTS" != "1" ]; then
        echo -e "    ${GREEN}✓ Creating database: ${DB_NAME}${NC}"
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c \
            "CREATE DATABASE $DB_NAME;" 2>/dev/null || {
                echo -e "    ${RED}✗ Failed to create ${DB_NAME}${NC}"
                exit 1
            }
    else
        echo -e "    ${YELLOW}Database ${DB_NAME} already exists${NC}"
    fi
done

# ============================================
# Step 2: Run base functions on all databases
# ============================================
echo -e "\n${YELLOW}Step 2: Installing base functions...${NC}"

for DB_NAME in "${!DATABASES[@]}"; do
    echo -e "  → Installing in: ${BLUE}${DB_NAME}${NC}"
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -f common/base_functions.sql -q 2>/dev/null || {
            echo -e "    ${RED}✗ Failed to install base functions${NC}"
            exit 1
        }
    echo -e "    ${GREEN}✓ Base functions installed${NC}"
done

# ============================================
# Step 3: Run service-specific schemas
# ============================================
echo -e "\n${YELLOW}Step 3: Creating service schemas...${NC}"

for DB_NAME in "${!DATABASES[@]}"; do
    SCHEMA_FILE="${DATABASES[$DB_NAME]}"
    echo -e "  → Creating schema for: ${BLUE}${DB_NAME}${NC}"
    echo -e "    File: ${SCHEMA_FILE}"
    
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -f "$SCHEMA_FILE" -q 2>/dev/null || {
            echo -e "    ${RED}✗ Failed to create schema${NC}"
            exit 1
        }
    echo -e "    ${GREEN}✓ Schema created successfully${NC}"
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ All databases initialized!${NC}"
echo -e "${GREEN}========================================${NC}"

# ============================================
# Summary
# ============================================
echo -e "\n${YELLOW}Database Summary:${NC}"
for DB_NAME in "${!DATABASES[@]}"; do
    TABLE_COUNT=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc \
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'" 2>/dev/null || echo "0")
    echo -e "  • ${BLUE}${DB_NAME}${NC}: ${GREEN}${TABLE_COUNT} tables${NC}"
done

echo -e "\n${GREEN}✓ Setup complete!${NC}\n"