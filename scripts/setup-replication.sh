#!/bin/bash
# Setup Logical Replication between AWS RDS and GCP Cloud SQL
# This script helps configure the "One-Way Stream" for The Invincible Cloud

set -e

echo "================================"
echo "Logical Replication Setup"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if psql is installed
if ! command -v psql &> /dev/null; then
    echo "Error: psql (PostgreSQL client) is not installed"
    echo "Install with: sudo apt-get install postgresql-client"
    exit 1
fi

echo -e "${BLUE}Step 1: AWS RDS Configuration${NC}"
echo "-------------------------------"
echo "Run the following on AWS RDS:"
echo ""
echo "   CREATE PUBLICATION cloud_sync FOR ALL TABLES;"
echo ""

read -p "Have you created the publication on AWS RDS? (y/n): " aws_done

if [ "$aws_done" != "y" ]; then
    echo -e "${YELLOW}Please run the SQL in scripts/setup-aws-replication.sql on AWS RDS first.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Get AWS RDS Connection Details${NC}"
echo "----------------------------------------"
read -p "AWS RDS Private IP: " aws_rds_ip
read -p "AWS RDS Database Name (default: appdb): " aws_db_name
aws_db_name=${aws_db_name:-appdb}
read -p "AWS RDS Username (default: postgres): " aws_username
aws_username=${aws_username:-postgres}
read -sp "AWS RDS Password: " aws_password
echo ""

echo ""
echo -e "${BLUE}Step 3: GCP Cloud SQL Configuration${NC}"
echo "--------------------------------------"
echo "Run the following on GCP Cloud SQL:"
echo ""
echo "   CREATE SUBSCRIPTION cloud_sync_sub"
echo "   CONNECTION 'host=$aws_rds_ip port=5432 dbname=$aws_db_name user=$aws_username password=***'"
echo "   PUBLICATION cloud_sync;"
echo ""

# Test connection from GCP to AWS
echo -e "${YELLOW}Testing connectivity...${NC}"
echo "You can test the connection from a GCP VM or Cloud SQL Proxy with:"
echo "   telnet $aws_rds_ip 5432"
echo ""

echo -e "${BLUE}Step 4: Verify Replication${NC}"
echo "---------------------------"
echo "After creating the subscription, verify with:"
echo ""
echo "On AWS (Publisher):"
echo "   SELECT * FROM pg_publication;"
echo "   SELECT * FROM pg_replication_slots;"
echo ""
echo "On GCP (Subscriber):"
echo "   SELECT * FROM pg_subscription;"
echo "   SELECT * FROM pg_stat_subscription;"
echo ""

echo -e "${GREEN}Setup Complete!${NC}"
echo ""
echo "Test the replication:"
echo "1. Create a table on AWS: CREATE TABLE test_users (id SERIAL PRIMARY KEY, name TEXT);"
echo "2. Insert data: INSERT INTO test_users (name) VALUES ('Alice');"
echo "3. Check on GCP: SELECT * FROM test_users;"
echo ""
echo "If data appears on GCP, the replication is working!"
