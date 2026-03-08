-- GCP Cloud SQL: Create Subscription for Logical Replication
-- Run this on the GCP Cloud SQL PostgreSQL instance

-- 1. Ensure logical decoding is enabled (should already be set via database flags)
-- Verify with: SHOW cloudsql.logical_decoding;

-- 2. Create the subscription pointing to AWS RDS
-- Replace the following variables with actual values from your deployment:
-- <AWS_RDS_PRIVATE_IP>: The private IP of AWS RDS (output from terraform)
-- <DB_PASSWORD>: The password for the postgres user
-- <DB_NAME>: The database name (default: appdb)

CREATE SUBSCRIPTION cloud_sync_sub 
CONNECTION 'host=<AWS_RDS_PRIVATE_IP> port=5432 dbname=appdb user=postgres password=<DB_PASSWORD>' 
PUBLICATION cloud_sync;

-- 3. Verify the subscription was created and is working
-- \dRs+
-- or
-- SELECT * FROM pg_subscription;

-- 4. Check subscription status
-- SELECT subname, subenabled, subslotname, subpublications FROM pg_subscription;

-- 5. Check replication status
-- SELECT * FROM pg_stat_subscription;

-- Note: The subscription creates a replication slot on the publisher (AWS RDS).
-- If you need to drop and recreate the subscription:
-- DROP SUBSCRIPTION cloud_sync_sub;

-- Troubleshooting:
-- If replication doesn't start, check:
-- 1. VPN tunnel is active (ping between VPCs)
-- 2. Security groups allow port 5432 between 10.0.0.0/16 and 10.1.0.0/16
-- 3. MSS clamping is configured on VPN instances
-- 4. AWS RDS has rds.logical_replication = 1
-- 5. GCP Cloud SQL has cloudsql.logical_decoding = on
