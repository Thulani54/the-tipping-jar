-- Runs once, on first initialisation of the Postgres data volume.
-- Each microservice owns its own logical database on the shared instance.
CREATE DATABASE accounts_db;
CREATE DATABASE creators_db;
CREATE DATABASE payments_db;
CREATE DATABASE tips_db;
CREATE DATABASE blog_db;
CREATE DATABASE careers_db;
CREATE DATABASE enterprise_db;
CREATE DATABASE support_db;
CREATE DATABASE referrals_db;
CREATE DATABASE platform_db;
-- admin_portal owns no database (it is a read-only aggregator).
