-- =============================================================================
-- ENERGY TRADING ETL - DATABASE SETUP SCRIPT
-- =============================================================================
-- This script creates all necessary schemas and tables for the production system.
-- Run this after starting your PostgreSQL Docker container.
--
-- USAGE:
--   docker-compose exec postgres psql -U learner -d energy_learning -f setup_database.sql
--
-- Or connect manually:
--   docker-compose exec postgres psql -U learner -d energy_learning
--   Then paste this entire script
-- =============================================================================

-- Drop existing schemas if you want a clean start (CAUTION: Deletes all data!)
-- DROP SCHEMA IF EXISTS raw_data CASCADE;
-- DROP SCHEMA IF EXISTS staging CASCADE;
-- DROP SCHEMA IF EXISTS analytics CASCADE;
-- DROP SCHEMA IF EXISTS audit CASCADE;

-- =============================================================================
-- SCHEMA CREATION
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS raw_data;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS audit;

COMMENT ON SCHEMA raw_data IS 'Immutable landing zone for raw CSV files';
COMMENT ON SCHEMA staging IS 'Cleaned and validated data ready for transformation';
COMMENT ON SCHEMA analytics IS 'Production data products for consumption';
COMMENT ON SCHEMA audit IS 'ETL logs, data quality checks, and audit trails';

-- =============================================================================
-- RAW DATA SCHEMA - Landing Zone
-- =============================================================================

CREATE TABLE raw_data.settlement_prices_raw (
    -- Primary key
    raw_id BIGSERIAL PRIMARY KEY,
    
    -- Source file tracking
    source_file_name VARCHAR(255) NOT NULL,
    file_received_date DATE NOT NULL,
    
    -- Raw data columns (adjust based on actual CSV structure)
    instrument_id VARCHAR(50),
    instrument_name VARCHAR(255),
    price_date VARCHAR(50),  -- Stored as-is before cleaning
    settlement_price VARCHAR(50),
    currency VARCHAR(10),
    exchange_name VARCHAR(100),
    contract_month VARCHAR(20),
    
    -- Store entire row as JSON for complete audit trail
    raw_data_json JSONB,
    
    -- Audit fields
    ingestion_timestamp TIMESTAMP DEFAULT NOW(),
    ingested_by VARCHAR(50) DEFAULT 'etl_pipeline',
    
    -- Constraints
    CONSTRAINT chk_file_name_not_empty CHECK (source_file_name <> '')
);

-- Indexes for raw_data queries
CREATE INDEX idx_raw_file_name ON raw_data.settlement_prices_raw(source_file_name);
CREATE INDEX idx_raw_ingestion_ts ON raw_data.settlement_prices_raw(ingestion_timestamp);
CREATE INDEX idx_raw_price_date ON raw_data.settlement_prices_raw(price_date);
CREATE INDEX idx_raw_json ON raw_data.settlement_prices_raw USING GIN(raw_data_json);

COMMENT ON TABLE raw_data.settlement_prices_raw IS 'Immutable landing zone for raw settlement price data';

-- =============================================================================
-- STAGING SCHEMA - Cleaned Data
-- =============================================================================

CREATE TABLE staging.settlement_prices_staging (
    -- Primary key
    staging_id BIGSERIAL PRIMARY KEY,
    
    -- Reference to raw data
    raw_id BIGINT REFERENCES raw_data.settlement_prices_raw(raw_id),
    
    -- Cleaned business fields
    instrument_id VARCHAR(50) NOT NULL,
    instrument_name VARCHAR(255),
    price_date DATE NOT NULL,  -- Standardized to YYYY-MM-DD
    settlement_price DECIMAL(18, 6),  -- High precision for financial data
    currency VARCHAR(10),
    exchange_name VARCHAR(100) NOT NULL,
    contract_month DATE,  -- Normalized to first day of month
    
    -- Data quality flags
    has_null_price BOOLEAN DEFAULT FALSE,
    has_null_instrument BOOLEAN DEFAULT FALSE,
    is_duplicate BOOLEAN DEFAULT FALSE,
    validation_status VARCHAR(20) DEFAULT 'pending',  -- pending, valid, invalid, duplicate
    validation_errors TEXT,
    
    -- Audit fields
    processed_timestamp TIMESTAMP DEFAULT NOW(),
    processed_by VARCHAR(50) DEFAULT 'transformation_pipeline',
    
    -- Constraints
    CONSTRAINT chk_price_positive CHECK (settlement_price IS NULL OR settlement_price >= 0),
    CONSTRAINT chk_validation_status CHECK (validation_status IN ('pending', 'valid', 'invalid', 'duplicate'))
);

-- Indexes for staging queries
CREATE INDEX idx_staging_instrument ON staging.settlement_prices_staging(instrument_id);
CREATE INDEX idx_staging_price_date ON staging.settlement_prices_staging(price_date);
CREATE INDEX idx_staging_exchange ON staging.settlement_prices_staging(exchange_name);
CREATE INDEX idx_staging_validation ON staging.settlement_prices_staging(validation_status);
CREATE INDEX idx_staging_composite ON staging.settlement_prices_staging(instrument_id, price_date, exchange_name);

COMMENT ON TABLE staging.settlement_prices_staging IS 'Cleaned and validated settlement price data';

-- =============================================================================
-- ANALYTICS SCHEMA - Data Products
-- =============================================================================

CREATE TABLE analytics.market_prices (
    -- Primary key
    price_id BIGSERIAL PRIMARY KEY,
    
    -- Business unique key (generated column)
    unique_key VARCHAR(150) GENERATED ALWAYS AS 
        (instrument_id || '_' || price_date || '_' || exchange_name) STORED,
    
    -- Core business fields
    instrument_id VARCHAR(50) NOT NULL,
    instrument_name VARCHAR(255),
    price_date DATE NOT NULL,
    settlement_price DECIMAL(18, 6) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    exchange_name VARCHAR(100) NOT NULL,
    contract_month DATE,
    
    -- Calculated fields for BI (populated by ETL)
    previous_day_price DECIMAL(18, 6),
    daily_change DECIMAL(18, 6),
    daily_change_percent DECIMAL(8, 4),
    
    -- Data lineage
    source_file_name VARCHAR(255) NOT NULL,
    staging_id BIGINT REFERENCES staging.settlement_prices_staging(staging_id),
    
    -- Audit fields
    created_timestamp TIMESTAMP DEFAULT NOW(),
    updated_timestamp TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(50) DEFAULT 'data_product_pipeline',
    data_version INT DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Constraints
    CONSTRAINT uq_market_prices UNIQUE (instrument_id, price_date, exchange_name),
    CONSTRAINT chk_price_not_null CHECK (settlement_price IS NOT NULL),
    CONSTRAINT chk_price_valid CHECK (settlement_price >= 0)
);

-- High-performance indexes for API queries
CREATE INDEX idx_mp_instrument ON analytics.market_prices(instrument_id) WHERE is_active = TRUE;
CREATE INDEX idx_mp_price_date ON analytics.market_prices(price_date) WHERE is_active = TRUE;
CREATE INDEX idx_mp_exchange ON analytics.market_prices(exchange_name) WHERE is_active = TRUE;
CREATE INDEX idx_mp_composite ON analytics.market_prices(instrument_id, price_date, exchange_name) WHERE is_active = TRUE;
CREATE INDEX idx_mp_unique_key ON analytics.market_prices(unique_key) WHERE is_active = TRUE;
CREATE INDEX idx_mp_updated ON analytics.market_prices(updated_timestamp);

COMMENT ON TABLE analytics.market_prices IS 'Production-ready settlement prices for API and BI consumption';

-- Materialized view for fast "latest prices" queries
CREATE MATERIALIZED VIEW analytics.mv_latest_prices AS
SELECT DISTINCT ON (instrument_id, exchange_name)
    instrument_id,
    instrument_name,
    price_date,
    settlement_price,
    currency,
    exchange_name,
    daily_change_percent,
    updated_timestamp
FROM analytics.market_prices
WHERE is_active = TRUE
ORDER BY instrument_id, exchange_name, price_date DESC;

CREATE UNIQUE INDEX idx_mv_latest_prices ON analytics.mv_latest_prices(instrument_id, exchange_name);

COMMENT ON MATERIALIZED VIEW analytics.mv_latest_prices IS 'Cached latest price per instrument - refresh after each ETL run';

-- =============================================================================
-- AUDIT SCHEMA - Observability & Compliance
-- =============================================================================

CREATE TABLE audit.etl_logs (
    log_id BIGSERIAL PRIMARY KEY,
    pipeline_name VARCHAR(100) NOT NULL,
    pipeline_stage VARCHAR(50) NOT NULL,  -- ingestion, validation, transformation, load
    execution_id UUID NOT NULL,  -- Groups log entries for a single pipeline run
    
    -- Status tracking
    status VARCHAR(20) NOT NULL,  -- started, running, completed, failed, warning
    message TEXT,
    error_details TEXT,
    stack_trace TEXT,
    
    -- Metrics
    records_processed INT DEFAULT 0,
    records_success INT DEFAULT 0,
    records_failed INT DEFAULT 0,
    execution_time_seconds DECIMAL(10, 3),
    
    -- Context
    source_file_name VARCHAR(255),
    parameters JSONB,
    
    -- Timestamps
    log_timestamp TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chk_status CHECK (status IN ('started', 'running', 'completed', 'failed', 'warning'))
);

CREATE INDEX idx_logs_pipeline ON audit.etl_logs(pipeline_name, pipeline_stage);
CREATE INDEX idx_logs_execution ON audit.etl_logs(execution_id);
CREATE INDEX idx_logs_timestamp ON audit.etl_logs(log_timestamp);
CREATE INDEX idx_logs_status ON audit.etl_logs(status);

COMMENT ON TABLE audit.etl_logs IS 'Complete audit trail of all ETL pipeline executions';

-- Data quality checks tracking
CREATE TABLE audit.data_quality_checks (
    check_id BIGSERIAL PRIMARY KEY,
    check_name VARCHAR(100) NOT NULL,
    check_type VARCHAR(50) NOT NULL,  -- completeness, accuracy, consistency, timeliness
    
    -- Results
    check_status VARCHAR(20) NOT NULL,  -- passed, failed, warning
    records_checked INT,
    records_failed INT,
    failure_rate DECIMAL(5, 2),
    
    -- Details
    check_details JSONB,
    threshold_value DECIMAL(18, 6),
    actual_value DECIMAL(18, 6),
    
    -- Context
    execution_id UUID,
    source_file_name VARCHAR(255),
    
    -- Timestamp
    check_timestamp TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT chk_quality_status CHECK (check_status IN ('passed', 'failed', 'warning'))
);

CREATE INDEX idx_quality_check_name ON audit.data_quality_checks(check_name);
CREATE INDEX idx_quality_timestamp ON audit.data_quality_checks(check_timestamp);
CREATE INDEX idx_quality_status ON audit.data_quality_checks(check_status);

COMMENT ON TABLE audit.data_quality_checks IS 'Data quality metrics and thresholds tracking';

-- =============================================================================
-- SAMPLE DATA for Testing (Optional)
-- =============================================================================

-- Insert a sample raw record
INSERT INTO raw_data.settlement_prices_raw 
(source_file_name, file_received_date, instrument_id, instrument_name, price_date, 
 settlement_price, currency, exchange_name, contract_month, raw_data_json)
VALUES 
('CME_Settlement_2026-03-30.csv', '2026-03-30', 'CL_2026-04', 'Crude Oil WTI Apr 2026', 
 '2026-03-30', '75.50', 'USD', 'CME', '2026-04', 
 '{"instrument_id":"CL_2026-04","price":"75.50","date":"2026-03-30"}'::jsonb);

-- Insert corresponding staging record
INSERT INTO staging.settlement_prices_staging
(raw_id, instrument_id, instrument_name, price_date, settlement_price, 
 currency, exchange_name, contract_month, validation_status)
VALUES 
(1, 'CL_2026-04', 'Crude Oil WTI Apr 2026', '2026-03-30', 75.50, 
 'USD', 'CME', '2026-04-01', 'valid');

-- Insert final analytics record with calculated fields
INSERT INTO analytics.market_prices
(instrument_id, instrument_name, price_date, settlement_price, currency, 
 exchange_name, contract_month, previous_day_price, daily_change, 
 daily_change_percent, source_file_name, staging_id)
VALUES 
('CL_2026-04', 'Crude Oil WTI Apr 2026', '2026-03-30', 75.50, 'USD', 
 'CME', '2026-04-01', 75.25, 0.25, 0.33, 
 'CME_Settlement_2026-03-30.csv', 1);

-- Log the ETL execution
INSERT INTO audit.etl_logs
(pipeline_name, pipeline_stage, execution_id, status, message, 
 records_processed, records_success, execution_time_seconds, source_file_name)
VALUES 
('settlement_prices_pipeline', 'load', 
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 'completed', 
 'Successfully loaded settlement prices', 1, 1, 0.523, 
 'CME_Settlement_2026-03-30.csv');

-- Log a data quality check
INSERT INTO audit.data_quality_checks
(check_name, check_type, check_status, records_checked, records_failed, 
 failure_rate, threshold_value, actual_value, execution_id, source_file_name)
VALUES 
('null_price_check', 'completeness', 'passed', 1, 0, 0.00, 
 0.00, 0.00, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 
 'CME_Settlement_2026-03-30.csv');

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Verify all tables were created
SELECT 
    schemaname, 
    tablename, 
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables 
WHERE schemaname IN ('raw_data', 'staging', 'analytics', 'audit')
ORDER BY schemaname, tablename;

-- Verify sample data
SELECT 'Raw Data Count:' AS check, COUNT(*) AS count FROM raw_data.settlement_prices_raw
UNION ALL
SELECT 'Staging Count:', COUNT(*) FROM staging.settlement_prices_staging
UNION ALL
SELECT 'Analytics Count:', COUNT(*) FROM analytics.market_prices
UNION ALL
SELECT 'Audit Logs:', COUNT(*) FROM audit.etl_logs
UNION ALL
SELECT 'Quality Checks:', COUNT(*) FROM audit.data_quality_checks;

-- View sample analytics record
SELECT 
    instrument_id,
    instrument_name,
    price_date,
    settlement_price,
    daily_change_percent,
    exchange_name
FROM analytics.market_prices
LIMIT 5;

-- =============================================================================
-- GRANT PERMISSIONS (Create read-only role for BI/Excel users)
-- =============================================================================

-- Create read-only role
CREATE ROLE readonly_user WITH LOGIN PASSWORD 'readonly_pass123';

-- Grant connect permission
GRANT CONNECT ON DATABASE energy_learning TO readonly_user;

-- Grant usage on analytics schema only
GRANT USAGE ON SCHEMA analytics TO readonly_user;

-- Grant select on all current and future tables in analytics
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO readonly_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT ON TABLES TO readonly_user;

-- Prevent write access
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA analytics FROM readonly_user;

COMMENT ON ROLE readonly_user IS 'Read-only access for Excel and Power BI users';

-- =============================================================================
-- SUCCESS MESSAGE
-- =============================================================================

DO $$ 
BEGIN 
    RAISE NOTICE '✅ Database setup complete!';
    RAISE NOTICE '📊 Schemas created: raw_data, staging, analytics, audit';
    RAISE NOTICE '📋 Tables created: 7 tables total';
    RAISE NOTICE '🔍 Sample data inserted for testing';
    RAISE NOTICE '👤 Read-only user created: readonly_user';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Next steps:';
    RAISE NOTICE '1. Verify tables: SELECT * FROM analytics.market_prices;';
    RAISE NOTICE '2. Start building the ETL pipeline';
    RAISE NOTICE '3. Connect Power BI using readonly_user credentials';
END $$;
