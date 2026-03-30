# Energy Trading Settlement Prices ETL - Production Implementation Plan

## Executive Summary

A production-grade ETL system to ingest, transform, and serve daily settlement prices from exchanges for trading and risk teams. The system will support Excel users, BI dashboards (Power BI), and automated trading systems via API.

**Tech Stack:**
- **Database:** PostgreSQL (Docker local → AWS RDS migration path)
- **ETL Pipeline:** Python 3.11+ with Pandas, SQLAlchemy
- **API Layer:** FastAPI with Pydantic validation
- **Orchestration:** Apache Airflow / Prefect (optional) or scheduled scripts
- **Storage:** AWS S3 (SFTP simulation)
- **Monitoring:** Prometheus + Grafana / CloudWatch
- **CI/CD:** GitHub Actions
- **Visualization:** Power BI connected via API

---

## Business Requirements Recap

### Primary Users
1. **Trading Teams** - Need accurate daily settlement prices for valuations
2. **Risk Management** - Require historical price data for risk calculations
3. **Excel Users** - Access via API or direct database connections
4. **BI Dashboards** - Power BI for trend analysis and variance reporting
5. **Trading Systems** - Automated consumption via REST API

### Data Flow
```
Exchange/Vendor → SFTP/S3 (CSV) → Ingestion Pipeline → PostgreSQL → FastAPI → Consumers
                                         ↓
                                   Quality Checks
                                         ↓
                                   Data Product Table
```

---

## System Architecture

### High-Level Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                              │
│  S3 Bucket (SFTP Simulation) - Daily CSV/Excel Files            │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    INGESTION LAYER                               │
│  - File Detection (S3 Event/Polling)                            │
│  - Raw Data Loading                                              │
│  - Schema Validation                                             │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                   POSTGRESQL DATABASE                            │
│  Schemas:                                                        │
│   • raw_data - Landing zone for unprocessed files               │
│   • staging - Cleaned and validated data                        │
│   • analytics - Final data products                             │
│   • audit - Logs, errors, data lineage                          │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                 TRANSFORMATION LAYER                             │
│  - Data Quality Checks                                           │
│  - Date Standardization                                          │
│  - Deduplication                                                 │
│  - Business Rules Application                                    │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                     API LAYER (FastAPI)                          │
│  Endpoints:                                                      │
│   • GET /getprices?trade_date=YYYY-MM-DD&source=EXCHANGE        │
│   • GET /health - System health check                           │
│   • GET /instruments - List available instruments               │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                   CONSUMPTION LAYER                              │
│  - Power BI Dashboards                                           │
│  - Excel Power Query                                             │
│  - Trading Systems                                               │
│  - Direct SQL Access (read-only role)                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Database Design

### Schema Structure

#### 1. **raw_data.settlement_prices_raw**
Landing zone for initial file ingestion - immutable.

```sql
CREATE SCHEMA IF NOT EXISTS raw_data;

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
    
    -- Additional raw columns as TEXT for flexibility
    raw_data_json JSONB,  -- Store entire row as JSON for audit
    
    -- Audit fields
    ingestion_timestamp TIMESTAMP DEFAULT NOW(),
    ingested_by VARCHAR(50) DEFAULT 'etl_pipeline',
    
    -- Constraints
    CONSTRAINT chk_file_name_not_empty CHECK (source_file_name <> '')
);

-- Indexes for performance
CREATE INDEX idx_raw_file_name ON raw_data.settlement_prices_raw(source_file_name);
CREATE INDEX idx_raw_ingestion_ts ON raw_data.settlement_prices_raw(ingestion_timestamp);
CREATE INDEX idx_raw_price_date ON raw_data.settlement_prices_raw(price_date);
```

#### 2. **staging.settlement_prices_staging**
Cleaned and validated data ready for transformation.

```sql
CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE staging.settlement_prices_staging (
    -- Primary key
    staging_id BIGSERIAL PRIMARY KEY,
    
    -- Reference to raw data
    raw_id BIGINT REFERENCES raw_data.settlement_prices_raw(raw_id),
    
    -- Cleaned business fields
    instrument_id VARCHAR(50) NOT NULL,
    instrument_name VARCHAR(255),
    price_date DATE NOT NULL,  -- Standardized to YYYY-MM-DD
    settlement_price DECIMAL(18, 6),  -- Precision for financial data
    currency VARCHAR(10),
    exchange_name VARCHAR(100) NOT NULL,
    contract_month DATE,  -- Normalized to first day of month
    
    -- Data quality flags
    has_null_price BOOLEAN DEFAULT FALSE,
    has_null_instrument BOOLEAN DEFAULT FALSE,
    is_duplicate BOOLEAN DEFAULT FALSE,
    validation_status VARCHAR(20) DEFAULT 'pending',  -- pending, valid, invalid
    validation_errors TEXT,
    
    -- Audit fields
    processed_timestamp TIMESTAMP DEFAULT NOW(),
    processed_by VARCHAR(50) DEFAULT 'transformation_pipeline',
    
    -- Constraints
    CONSTRAINT chk_price_positive CHECK (settlement_price IS NULL OR settlement_price >= 0),
    CONSTRAINT chk_validation_status CHECK (validation_status IN ('pending', 'valid', 'invalid', 'duplicate'))
);

-- Indexes
CREATE INDEX idx_staging_instrument ON staging.settlement_prices_staging(instrument_id);
CREATE INDEX idx_staging_price_date ON staging.settlement_prices_staging(price_date);
CREATE INDEX idx_staging_exchange ON staging.settlement_prices_staging(exchange_name);
CREATE INDEX idx_staging_validation ON staging.settlement_prices_staging(validation_status);
CREATE INDEX idx_staging_composite ON staging.settlement_prices_staging(instrument_id, price_date, exchange_name);
```

#### 3. **analytics.market_prices** (Data Product)
Final production table optimized for reporting and API consumption.

```sql
CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE analytics.market_prices (
    -- Composite primary key
    price_id BIGSERIAL PRIMARY KEY,
    
    -- Business unique key
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
    
    -- Calculated fields for BI
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

-- Indexes for API performance
CREATE INDEX idx_mp_instrument ON analytics.market_prices(instrument_id) WHERE is_active = TRUE;
CREATE INDEX idx_mp_price_date ON analytics.market_prices(price_date) WHERE is_active = TRUE;
CREATE INDEX idx_mp_exchange ON analytics.market_prices(exchange_name) WHERE is_active = TRUE;
CREATE INDEX idx_mp_composite ON analytics.market_prices(instrument_id, price_date, exchange_name) WHERE is_active = TRUE;
CREATE INDEX idx_mp_unique_key ON analytics.market_prices(unique_key) WHERE is_active = TRUE;
CREATE INDEX idx_mp_updated ON analytics.market_prices(updated_timestamp);

-- Materialized view for performance (optional)
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
```

#### 4. **audit.etl_logs**
Comprehensive audit trail for all ETL operations.

```sql
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE audit.etl_logs (
    log_id BIGSERIAL PRIMARY KEY,
    pipeline_name VARCHAR(100) NOT NULL,
    pipeline_stage VARCHAR(50) NOT NULL,  -- ingestion, validation, transformation, load
    execution_id UUID NOT NULL,  -- Group related log entries
    
    -- Status tracking
    status VARCHAR(20) NOT NULL,  -- started, running, completed, failed, warning
    message TEXT,
    error_details TEXT,
    
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
```

#### 5. **audit.data_quality_checks**
Track data quality metrics over time.

```sql
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
```

---

## Project Structure

```
energy-etl/
├── .github/
│   └── workflows/
│       ├── ci.yml                    # CI/CD pipeline
│       ├── deploy.yml                # Deployment workflow
│       └── data-quality.yml          # Scheduled quality checks
│
├── src/
│   ├── __init__.py
│   ├── config/
│   │   ├── __init__.py
│   │   ├── settings.py               # Environment configs (Pydantic BaseSettings)
│   │   ├── database.py               # DB connection management
│   │   └── logging_config.py         # Structured logging setup
│   │
│   ├── ingestion/
│   │   ├── __init__.py
│   │   ├── file_detector.py          # S3/SFTP file detection
│   │   ├── csv_parser.py             # CSV/Excel parsing with validation
│   │   ├── raw_loader.py             # Load to raw_data schema
│   │   └── validators.py             # Schema validation (Pydantic models)
│   │
│   ├── transformation/
│   │   ├── __init__.py
│   │   ├── data_cleaner.py           # Date standardization, null handling
│   │   ├── deduplication.py          # Remove duplicates
│   │   ├── enrichment.py             # Calculate daily changes, etc.
│   │   └── data_quality.py           # Quality checks implementation
│   │
│   ├── database/
│   │   ├── __init__.py
│   │   ├── models.py                 # SQLAlchemy ORM models
│   │   ├── repository.py             # Data access layer
│   │   └── migrations/               # Alembic migrations
│   │       ├── versions/
│   │       └── env.py
│   │
│   ├── api/
│   │   ├── __init__.py
│   │   ├── main.py                   # FastAPI app initialization
│   │   ├── routers/
│   │   │   ├── __init__.py
│   │   │   ├── prices.py             # /getprices endpoint
│   │   │   ├── health.py             # Health check endpoints
│   │   │   └── instruments.py        # Metadata endpoints
│   │   ├── schemas/
│   │   │   ├── __init__.py
│   │   │   ├── requests.py           # Request Pydantic models
│   │   │   └── responses.py          # Response Pydantic models
│   │   ├── dependencies.py           # Dependency injection
│   │   ├── middleware.py             # Logging, auth, CORS
│   │   └── exceptions.py             # Custom exception handlers
│   │
│   ├── orchestration/
│   │   ├── __init__.py
│   │   ├── daily_pipeline.py         # Main ETL orchestration
│   │   └── airflow_dags/             # If using Airflow
│   │       └── settlement_prices_dag.py
│   │
│   └── utils/
│       ├── __init__.py
│       ├── logger.py                 # Logging utilities
│       ├── notifications.py          # Email/Slack alerts
│       └── s3_client.py              # AWS S3 operations
│
├── tests/
│   ├── __init__.py
│   ├── unit/
│   │   ├── test_ingestion.py
│   │   ├── test_transformation.py
│   │   └── test_api.py
│   ├── integration/
│   │   ├── test_end_to_end.py
│   │   └── test_database.py
│   └── fixtures/
│       ├── sample_csv_valid.csv
│       └── sample_csv_invalid.csv
│
├── scripts/
│   ├── setup_database.sql            # Initial DB setup
│   ├── create_read_only_user.sql     # For Excel/BI users
│   ├── backfill_data.py              # Historical data loading
│   └── health_check.py               # Monitoring script
│
├── monitoring/
│   ├── prometheus_config.yml
│   ├── grafana_dashboard.json
│   └── alerts.yml                    # Alert rules
│
├── powerbi/
│   ├── settlement_prices.pbix        # Power BI template
│   └── connection_guide.md           # Setup instructions
│
├── docker/
│   ├── Dockerfile.api                # API container
│   ├── Dockerfile.etl                # ETL pipeline container
│   └── docker-compose.prod.yml       # Production compose
│
├── docs/
│   ├── api_documentation.md
│   ├── deployment_guide.md
│   ├── user_guide.md
│   └── troubleshooting.md
│
├── .env.example                      # Environment variables template
├── .gitignore
├── docker-compose.yaml               # Local development
├── requirements.txt                  # Python dependencies
├── requirements-dev.txt              # Development dependencies
├── pyproject.toml                    # Project configuration
├── pytest.ini                        # Test configuration
├── alembic.ini                       # Database migrations config
└── README.md
```

---

## Implementation Approach

### Phase 1: Foundation (Week 1)
- Database schema setup
- PostgreSQL with proper schemas (raw_data, staging, analytics, audit)
- Connection management and pooling
- Logging infrastructure
- Basic CI/CD pipeline

### Phase 2: Ingestion Pipeline (Week 2)
- S3 file detection (event-driven or polling)
- CSV/Excel parser with schema validation
- Raw data loading with audit fields
- Error handling and retry logic
- Unit tests for ingestion

### Phase 3: Transformation Pipeline (Week 3)
- Data cleaning and standardization
- Deduplication logic
- Data quality checks
- Loading to analytics.market_prices
- Previous day price calculation
- Integration tests

### Phase 4: API Layer (Week 4)
- FastAPI application structure
- /getprices endpoint with validation
- Health check endpoints
- API documentation (Swagger/OpenAPI)
- Rate limiting and caching
- API tests

### Phase 5: Visualization & Monitoring (Week 5)
- Power BI dashboard development
- API connectivity setup
- Monitoring with Prometheus/Grafana
- Alerting rules
- Performance optimization

### Phase 6: Production Hardening (Week 6)
- Security audit
- Performance testing
- Load testing (API endpoints)
- Documentation completion
- Deployment automation
- User acceptance testing

---

## Best Practices Implementation

### 1. **Data Quality Framework**

```python
# src/transformation/data_quality.py

class DataQualityCheck:
    """Production-grade data quality framework"""
    
    CHECKS = {
        'completeness': {
            'null_instrument_id': 0.0,  # 0% null tolerance
            'null_price': 0.0,
            'null_date': 0.0,
        },
        'accuracy': {
            'price_negative': 0.0,  # No negative prices
            'future_dates': 0.0,    # No future dates
        },
        'consistency': {
            'duplicate_rate': 0.01,  # Max 1% duplicates
        },
        'timeliness': {
            'file_age_hours': 24,  # File must be < 24 hours old
        }
    }
    
    @staticmethod
    def run_all_checks(df, execution_id):
        """Run all quality checks and log results"""
        # Implementation with detailed logging
```

### 2. **Idempotency Pattern**

All pipelines must be rerunnable without side effects:
- Use UPSERT patterns (INSERT ON CONFLICT UPDATE)
- Track execution_id for all operations
- Implement proper transaction boundaries
- Enable replay of failed batches

### 3. **Security Considerations**

- **Database Credentials:** Use AWS Secrets Manager or environment variables
- **API Authentication:** Implement API key authentication (FastAPI dependencies)
- **Read-Only Users:** Separate role for Excel/BI consumption
- **SQL Injection Prevention:** Use parameterized queries (SQLAlchemy)
- **Network Security:** VPC, security groups, SSL/TLS for all connections

### 4. **Error Handling Strategy**

```python
# Three-tier error handling

1. Transient Errors → Retry with exponential backoff
   - Network failures
   - Database connection issues
   
2. Data Quality Errors → Log and continue
   - Invalid records quarantined
   - Alert sent to data team
   
3. System Errors → Fail fast and alert
   - Schema mismatches
   - Missing critical configuration
```

### 5. **Observability**

- **Logging:** Structured JSON logs with correlation IDs
- **Metrics:** Track processing time, record counts, error rates
- **Tracing:** Distributed tracing for debugging
- **Alerting:** Prometheus alerts for SLA violations

### 6. **Performance Optimization**

- **Bulk Operations:** Use COPY or bulk inserts (not row-by-row)
- **Indexing Strategy:** Composite indexes on query patterns
- **Connection Pooling:** SQLAlchemy pool with appropriate sizing
- **API Caching:** Redis cache for frequently accessed data
- **Database Partitioning:** Consider partitioning by price_date for large volumes

---

## API Design

### Endpoint: GET /getprices

**Request:**
```http
GET /getprices?trade_date=2026-03-30&source=CME&instrument_id=CL_2026-04
Authorization: Bearer <api_key>
```

**Parameters:**
- `trade_date` (required): YYYY-MM-DD format
- `source` (required): Exchange name (CME, ICE, NYMEX, etc.)
- `instrument_id` (optional): Filter by specific instrument
- `limit` (optional): Pagination limit (default 100, max 1000)
- `offset` (optional): Pagination offset

**Response (Success - 200):**
```json
{
  "status": "success",
  "metadata": {
    "trade_date": "2026-03-30",
    "source": "CME",
    "record_count": 15,
    "query_time_ms": 45,
    "retrieved_at": "2026-03-30T10:15:19Z"
  },
  "data": [
    {
      "instrument_id": "CL_2026-04",
      "instrument_name": "Crude Oil WTI Apr 2026",
      "price_date": "2026-03-30",
      "settlement_price": 75.50,
      "currency": "USD",
      "exchange_name": "CME",
      "contract_month": "2026-04-01",
      "previous_day_price": 75.25,
      "daily_change": 0.25,
      "daily_change_percent": 0.33,
      "source_file_name": "CME_Settlement_2026-03-30.csv",
      "updated_timestamp": "2026-03-30T08:30:00Z"
    }
  ],
  "pagination": {
    "limit": 100,
    "offset": 0,
    "has_more": false
  }
}
```

**Response (Error - 404):**
```json
{
  "status": "error",
  "error_code": "NO_DATA_FOUND",
  "message": "No settlement prices found for trade_date=2026-03-30 and source=CME",
  "details": {
    "trade_date": "2026-03-30",
    "source": "CME"
  }
}
```

**Response (Error - 400):**
```json
{
  "status": "error",
  "error_code": "INVALID_REQUEST",
  "message": "Validation error",
  "details": {
    "trade_date": "Invalid date format. Expected YYYY-MM-DD"
  }
}
```

---

## Power BI Dashboard Design

### Dashboard 1: Price Trends
- **Line Chart:** Settlement price over time (last 30/90/365 days)
- **Slicers:** Instrument, Exchange, Date Range
- **KPI Cards:** Latest Price, 30-day High, 30-day Low, Average

### Dashboard 2: Daily Variance Analysis
- **Table:** Instrument | Latest Price | Previous Price | Change | Change %
- **Conditional Formatting:** Green for positive, red for negative
- **Sparklines:** 7-day trend for each instrument
- **Filters:** Exchange, Date, Price Change % threshold

### Dashboard 3: Data Quality Monitor
- **Gauge:** Data completeness score
- **Bar Chart:** Records processed by day
- **Table:** Failed quality checks
- **Alert Panel:** Missing files or SLA violations

---

## Testing Strategy

### 1. Unit Tests (90%+ coverage target)
- Ingestion parsing logic
- Transformation rules
- API endpoint handlers
- Data quality checks

### 2. Integration Tests
- End-to-end pipeline (CSV → Database)
- API integration with database
- S3 event trigger simulation

### 3. Performance Tests
- API load testing (100 concurrent users)
- Database query performance
- Large file processing (1M+ records)

### 4. Data Quality Tests
- Schema validation
- Business rule enforcement
- Duplicate detection accuracy

---

## Deployment Strategy

### Local Development
```bash
docker-compose up -d  # PostgreSQL
python -m src.api.main  # FastAPI local
pytest  # Run tests
```

### Production (AWS)
1. **Database:** RDS PostgreSQL with Multi-AZ
2. **API:** ECS Fargate or Lambda (for serverless)
3. **ETL:** Lambda + EventBridge or ECS scheduled tasks
4. **Storage:** S3 with lifecycle policies
5. **Monitoring:** CloudWatch + SNS alerts

### CI/CD Pipeline
```yaml
# .github/workflows/ci.yml
- Lint (black, flake8, mypy)
- Unit tests
- Integration tests
- Build Docker images
- Deploy to staging
- Smoke tests
- Deploy to production (manual approval)
```

---

## Monitoring & Alerting

### Metrics to Track
1. **Pipeline Health**
   - Files processed per day
   - Processing time (SLA: < 15 minutes)
   - Error rate (target: < 0.1%)

2. **Data Quality**
   - Completeness score (target: > 99.9%)
   - Duplicate rate (target: 0%)
   - Schema validation failures

3. **API Performance**
   - Response time (p95 < 200ms)
   - Error rate (target: < 0.01%)
   - Request rate

### Alert Rules
- **Critical:** Pipeline failure, API down, database unreachable
- **Warning:** Data quality below threshold, file delayed > 2 hours
- **Info:** Daily summary report

---

## Migration Path: Local → Production

### Step 1: Database Migration
```python
# Update connection string in config/settings.py
# From: postgresql://learner:learning123@localhost:5432/energy_learning
# To: postgresql://{user}:{pass}@{rds-endpoint}:5432/energy_production
```

### Step 2: S3 Integration
```python
# Replace local file reads with boto3 S3 operations
import boto3
s3_client = boto3.client('s3')
```

### Step 3: Containerization
```dockerfile
# Build and push Docker images
docker build -f docker/Dockerfile.api -t energy-api:latest .
docker push {ecr-repo}/energy-api:latest
```

### Step 4: Infrastructure as Code
```terraform
# Optional: Terraform for infrastructure
# Define RDS, ECS, S3, IAM, etc.
```

---

## Success Criteria

✅ **Functional Requirements**
- [ ] Daily files automatically ingested from S3
- [ ] Data quality checks pass > 99.5% of the time
- [ ] API responds within 200ms for 95th percentile
- [ ] Power BI dashboard updates automatically
- [ ] Zero duplicate prices in production table
- [ ] All transformations are auditable

✅ **Non-Functional Requirements**
- [ ] 99.9% uptime for API
- [ ] Data available within 15 minutes of file arrival
- [ ] System handles 10x current data volume
- [ ] All secrets stored securely
- [ ] Comprehensive logging and monitoring
- [ ] CI/CD pipeline fully automated

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| File not delivered | High | Alert after 2-hour delay, manual investigation |
| Schema change from vendor | High | Schema validation with version tracking |
| Database connection pool exhaustion | Medium | Connection pool monitoring, auto-scaling |
| API rate limiting abuse | Medium | Implement rate limiting, API key quotas |
| Data duplication | High | Unique constraints, automated deduplication |
| Performance degradation | Medium | Query optimization, caching, indexing strategy |

---

## Next Steps

1. Review and approve this plan
2. Set up development environment
3. Create database schemas
4. Implement ingestion pipeline
5. Build transformation layer
6. Develop FastAPI application
7. Create Power BI dashboards
8. Deploy to production
9. User training and handoff

---

## Notes

- This plan assumes Python 3.11+, PostgreSQL 14+, FastAPI 0.110+
- Adjust timelines based on team size and complexity
- Consider Airflow for complex orchestration needs
- All code should follow PEP 8 style guidelines
- Use type hints throughout (mypy strict mode)
- Implement comprehensive error handling at every layer
- Document all business logic and assumptions
