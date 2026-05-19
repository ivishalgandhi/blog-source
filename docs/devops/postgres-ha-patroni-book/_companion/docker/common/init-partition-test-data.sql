-- Partition Test Data Initialization
-- Creates a test schema with a transactions table for data consistency verification.
-- Run via: psql -U postgres -d postgres -f /tmp/init-partition-test-data.sql

CREATE SCHEMA IF NOT EXISTS partition_test;

DROP TABLE IF EXISTS partition_test.transactions;

CREATE TABLE partition_test.transactions (
    id          SERIAL PRIMARY KEY,
    node_name   TEXT NOT NULL,
    ts          TIMESTAMPTZ DEFAULT NOW(),
    payload     TEXT
);

-- Insert seed rows from each node to establish a baseline checksum
INSERT INTO partition_test.transactions (node_name, payload)
SELECT 'init', md5(generate_series::text)
FROM generate_series(1, 100);

-- Grant select to all for verification queries
GRANT USAGE ON SCHEMA partition_test TO PUBLIC;
GRANT SELECT ON TABLE partition_test.transactions TO PUBLIC;

-- Return row count and MD5 checksum of the table
SELECT
    count(*) AS row_count,
    md5(string_agg(id::text || ':' || node_name || ':' || payload, ',' ORDER BY id)) AS checksum
FROM partition_test.transactions;
