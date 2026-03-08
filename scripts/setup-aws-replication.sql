-- AWS RDS: Create Publication for Logical Replication
-- Run this on the AWS RDS PostgreSQL instance

-- 1. Ensure logical replication is enabled (should already be set via parameter group)
-- Verify with: SHOW rds.logical_replication;

-- 2. Create a publication for all tables (or specify specific tables)
CREATE PUBLICATION cloud_sync FOR ALL TABLES;

-- Alternative: Create publication for specific tables only
-- CREATE PUBLICATION cloud_sync FOR TABLE users, tasks;

-- 3. Verify the publication was created
-- \dRp+
-- or
-- SELECT * FROM pg_publication;

-- 4. Check publication tables
-- SELECT * FROM pg_publication_tables;

-- Note: After creating the publication, you'll need to create a subscription
-- on the GCP Cloud SQL instance pointing to this AWS RDS instance.
-- The subscription command will look like:
-- CREATE SUBSCRIPTION cloud_sync_sub 
-- CONNECTION 'host=<AWS_RDS_PRIVATE_IP> port=5432 dbname=appdb user=postgres password=<password>' 
-- PUBLICATION cloud_sync;
