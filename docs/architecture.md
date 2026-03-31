# 🏗️ System Architecture Documentation

## Overview

This document provides a detailed technical architecture of the Energy ETL system, including components, data flows, and design decisions.

---

## 🎯 Architecture Principles

1. **Separation of Concerns** - Clear boundaries between ingestion, transformation, and serving layers
2. **Idempotency** - Re-running pipelines produces same results
3. **Auditability** - Complete lineage from source file to final data
4. **Scalability** - Can handle growing data volumes
5. **Data Quality** - Multiple validation layers before production use
6. **Resilience** - Graceful error handling and recovery

---

## 📊 System Components

### 1. Data Ingestion Layer

**Purpose:** Extract raw settlement price files and load to database.

**Components:**

```
┌─────────────────────────────────────────────┐
│        S3 Bucket (Raw Data Zone)            │
│   - CME_settlements_YYYY-MM-DD.csv         │
│   - ICE_settlements_YYYY-MM-DD.xlsx        │
│   - NYMEX_settlements_YYYY-MM-DD.csv       │
└────────────────┬────────────────────────────┘
                 │
                 │ S3 Event / Polling
                 ▼
┌─────────────────────────────────────────────┐
│     File Detection Service                  │
│   - Monitor S3 for new files               │
│   - Trigger ingestion pipeline             │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│     CSV/Excel Parser                        │
│   - Validate file format                   │
│   - Parse columns                          │
│   - Handle encoding (UTF-8, Latin-1)       │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  raw_data.settlement_prices_raw             │
│   - Immutable landing zone                 │
│   - Store as-is with metadata              │
└─────────────────────────────────────────────┘
```

**Technologies:**
- **boto3** - S3 file operations
- **pandas** - CSV/Excel parsing
- **psycopg2** - PostgreSQL connector
- **SQLAlchemy** - ORM and connection pooling

**Key Files:**
- `src/etl/ingest_settlement_prices.py` - Main ingestion script
- `src/parsers/csv_parser.py` - CSV parsing logic
- `src/parsers/excel_parser.py` - Excel parsing logic
- `src/database/loaders.py` - Database insertion

---

### 2. Data Transformation Layer

**Purpose:** Clean, validate, and transform raw data into analytics-ready format.

**Pipeline Stages:**

```
raw_data.settlement_prices_raw
    ↓
    ├─→ [Date Standardization]
    │    - YYYY-MM-DD format
    │    - Timezone normalization
    │    - Business day validation
    ↓
    ├─→ [Data Type Conversion]
    │    - String → Decimal (prices)
    │    - String → Date
    │    - NULL handling
    ↓
    ├─→ [Deduplication]
    │    - Remove exact duplicates
    │    - Keep latest for conflicts
    ↓
    ├─→ [Data Quality Checks]
    │    - Price range validation
    │    - Completeness checks
    │    - Outlier detection
    │    - Cross-field validation
    ↓
staging.settlement_prices_staging
    ↓
    ├─→ [Business Logic]
    │    - Calculate daily changes
    │    - Calculate % changes
    │    - Enrich with instrument metadata
    ↓
    ├─→ [Final Validation]
    │    - Referential integrity
    │    - Business rules
    ↓
analytics.market_prices
```

**Technologies:**
- **pandas** - Data manipulation
- **numpy** - Numerical operations
- **pydantic** - Data validation
- **Great Expectations** - Data quality framework (future)

**Key Files:**
- `src/etl/transform_to_staging.py` - Raw → Staging
- `src/etl/transform_to_analytics.py` - Staging → Analytics
- `src/validation/price_validators.py` - Price range checks
- `src/validation/quality_checks.py` - Data quality rules

---

### 3. Database Layer (4-Schema Design)

#### Schema 1: raw_data

**Purpose:** Immutable landing zone for raw files.

**Tables:**
- `settlement_prices_raw` - Raw CSV/Excel data
- `file_inventory` - Catalog of ingested files

**Characteristics:**
- Never modified after insert
- Stores original values as text
- Full JSON backup of each row
- Enables audit trail and reprocessing

#### Schema 2: staging

**Purpose:** Cleaned and validated data ready for transformation.

**Tables:**
- `settlement_prices_staging` - Cleaned data
- `validation_errors` - Records that failed validation

**Characteristics:**
- Standardized data types
- Quality flags
- References back to raw_data
- Can be truncated and rebuilt

#### Schema 3: analytics

**Purpose:** Production data products consumed by users.

**Tables:**
- `market_prices` - Main fact table (settlement prices)
- `instruments` - Instrument metadata
- `exchanges` - Exchange information
- `trading_calendar` - Business days calendar

**Characteristics:**
- Optimized for read performance
- Indexed for fast queries
- Served via API
- Business logic applied

#### Schema 4: audit

**Purpose:** Logging, monitoring, and data lineage.

**Tables:**
- `etl_run_log` - Pipeline execution history
- `data_quality_checks` - Quality check results
- `api_request_log` - API usage tracking
- `data_lineage` - Raw → Staging → Analytics mapping

**Characteristics:**
- Append-only
- Retention policy (archive after 2 years)
- Enables troubleshooting

---

### 4. API Layer (FastAPI)

**Purpose:** Serve data to consumers via REST API.

**Architecture:**

```
                   ┌─────────────────┐
                   │  Load Balancer  │
                   │   (AWS ALB)     │
                   └────────┬────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
  ┌──────────┐      ┌──────────┐      ┌──────────┐
  │ FastAPI  │      │ FastAPI  │      │ FastAPI  │
  │Container │      │Container │      │Container │
  │  (ECS)   │      │  (ECS)   │      │  (ECS)   │
  └────┬─────┘      └────┬─────┘      └────┬─────┘
       │                 │                  │
       └─────────────────┼──────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  RDS PostgreSQL      │
              │  (Read Replica Pool) │
              └──────────────────────┘
```

**Components:**

1. **Endpoints** - REST API routes
2. **Validators** - Pydantic models for request/response
3. **Database Layer** - SQLAlchemy queries
4. **Caching** - Redis for frequently accessed data
5. **Rate Limiting** - Prevent abuse
6. **Authentication** - API key validation

**Technologies:**
- **FastAPI** - Web framework
- **Uvicorn** - ASGI server
- **SQLAlchemy** - ORM
- **Redis** - Caching
- **Pydantic** - Validation

**Key Files:**
- `src/api/main.py` - FastAPI app initialization
- `src/api/routes/prices.py` - Price endpoints
- `src/api/routes/instruments.py` - Instrument endpoints
- `src/api/models/schemas.py` - Pydantic models
- `src/api/database/queries.py` - Database queries

---

### 5. Monitoring & Observability

**Metrics Collection:**

```
Application → CloudWatch Agent → CloudWatch Metrics
           ↘                   ↗
            → Prometheus Exporter → Grafana Dashboard
```

**Key Metrics:**

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| API Latency (p50) | < 200ms | > 500ms |
| API Latency (p99) | < 1s | > 2s |
| Error Rate | < 0.1% | > 1% |
| ETL Success Rate | 100% | < 99% |
| Database Connections | < 80% pool | > 90% pool |
| Data Freshness | < 2 hours | > 6 hours |

**Logging:**

```
Application Logs → CloudWatch Logs → Log Insights
                                   ↘
                                    → Alerts (SNS)
```

**Log Levels:**
- **DEBUG** - Development only
- **INFO** - Normal operations
- **WARNING** - Potential issues
- **ERROR** - Failures requiring attention
- **CRITICAL** - System-wide failures

---

## 🔄 Data Flows

### Flow 1: Daily Settlement Price Ingestion

```
Time: 6:00 PM CT Daily

1. Exchange publishes settlement prices (5:00 PM CT)
   ↓
2. Data vendor delivers file to S3 (5:30 PM CT)
   ↓
3. S3 event triggers Lambda function
   ↓
4. Lambda invokes ECS task (ingestion job)
   ↓
5. Ingestion job:
   - Downloads file from S3
   - Parses CSV/Excel
   - Validates schema
   - Inserts into raw_data schema
   - Records file in audit.file_inventory
   ↓
6. Transformation job (triggered by completion):
   - Reads from raw_data
   - Cleans and validates
   - Loads to staging schema
   - Runs quality checks
   - Loads to analytics schema
   ↓
7. Notification sent (6:30 PM CT):
   - Slack: "Daily prices loaded for 2024-03-15"
   - Email to stakeholders
   - CloudWatch custom metric
   ↓
8. Data available via API (6:30 PM CT)
```

### Flow 2: API Request

```
1. User sends GET request
   GET /api/v1/prices?trade_date=2024-03-15&exchange=CME
   ↓
2. Load Balancer → FastAPI container
   ↓
3. FastAPI:
   - Validates request (Pydantic)
   - Checks API key
   - Checks rate limit
   - Checks cache (Redis)
   ↓
4. If not cached:
   - Query PostgreSQL (read replica)
   - Transform to JSON
   - Cache result (1 hour TTL)
   ↓
5. Return response to user
   {
     "status": "success",
     "data": [...],
     "metadata": {...}
   }
   ↓
6. Log request to audit.api_request_log
```

---

## 🗄️ Database Schema Details

### Table: analytics.market_prices

**Purpose:** Main production table for settlement prices.

```sql
CREATE TABLE analytics.market_prices (
    price_id BIGSERIAL PRIMARY KEY,
    instrument_id VARCHAR(50) NOT NULL,
    instrument_name VARCHAR(255) NOT NULL,
    trade_date DATE NOT NULL,
    settlement_price DECIMAL(15,6) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    exchange VARCHAR(100) NOT NULL,
    contract_month VARCHAR(20),
    
    -- Calculated fields
    daily_change DECIMAL(15,6),
    percent_change DECIMAL(10,4),
    
    -- Volume and open interest
    volume BIGINT,
    open_interest BIGINT,
    
    -- Data quality
    data_quality_flag VARCHAR(50) DEFAULT 'VALID',
    quality_notes TEXT,
    
    -- Audit fields
    source_raw_id BIGINT REFERENCES raw_data.settlement_prices_raw(raw_id),
    source_staging_id BIGINT REFERENCES staging.settlement_prices_staging(staging_id),
    created_timestamp TIMESTAMP DEFAULT NOW(),
    updated_timestamp TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_instrument_trade_contract 
        UNIQUE (instrument_id, trade_date, contract_month),
    CONSTRAINT chk_settlement_price_positive 
        CHECK (settlement_price > 0),
    CONSTRAINT chk_trade_date_reasonable 
        CHECK (trade_date >= '2000-01-01' AND trade_date <= CURRENT_DATE + INTERVAL '2 years')
);

-- Indexes
CREATE INDEX idx_market_prices_trade_date ON analytics.market_prices(trade_date);
CREATE INDEX idx_market_prices_instrument ON analytics.market_prices(instrument_id);
CREATE INDEX idx_market_prices_exchange ON analytics.market_prices(exchange);
CREATE INDEX idx_market_prices_instrument_trade ON analytics.market_prices(instrument_id, trade_date);
CREATE INDEX idx_market_prices_contract_month ON analytics.market_prices(contract_month);
```

**Partitioning Strategy (Future):**

```sql
-- Partition by year for better performance
CREATE TABLE analytics.market_prices_2024 PARTITION OF analytics.market_prices
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE analytics.market_prices_2025 PARTITION OF analytics.market_prices
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

---

## 🔐 Security Architecture

### Network Security

```
Internet → CloudFront → ALB → ECS (Private Subnet) → RDS (Private Subnet)
                                     ↑                      ↑
                                     │                      │
                                  Security Groups      Security Groups
```

**Security Groups:**

1. **ALB Security Group**
   - Inbound: HTTPS (443) from Internet
   - Outbound: HTTP (8000) to ECS tasks

2. **ECS Security Group**
   - Inbound: HTTP (8000) from ALB
   - Outbound: PostgreSQL (5432) to RDS

3. **RDS Security Group**
   - Inbound: PostgreSQL (5432) from ECS
   - No outbound

### Data Security

**At Rest:**
- RDS encryption enabled (AES-256)
- S3 bucket encryption enabled
- EBS volumes encrypted

**In Transit:**
- TLS 1.2+ for all API connections
- SSL for database connections
- VPC endpoints for S3 (no internet)

**Access Control:**
- IAM roles for ECS tasks
- Read-only database user for API
- Secrets Manager for credentials
- API key authentication

---

## 📈 Scalability Design

### Horizontal Scaling

**API Layer:**
- Auto-scaling ECS tasks (2-10 containers)
- Trigger: CPU > 70% or latency > 500ms
- Scale-out: Add 1 container per minute
- Scale-in: Remove 1 container per 5 minutes

**Database Layer:**
- Read replicas (up to 5)
- Connection pooling (20 connections per API container)
- Query result caching (Redis)

**Storage:**
- S3 (unlimited)
- RDS storage auto-scaling (100GB → 1TB)

### Vertical Scaling

**RDS Instance Classes:**
- **Development:** db.t3.medium (2 vCPU, 4GB RAM)
- **Production:** db.r6g.xlarge (4 vCPU, 32GB RAM)
- **High Load:** db.r6g.2xlarge (8 vCPU, 64GB RAM)

---

## 🔄 Disaster Recovery

### Backup Strategy

**Database:**
- **Automated snapshots:** Daily at 3 AM UTC
- **Retention:** 7 days
- **Manual snapshots:** Before major changes
- **Point-in-time recovery:** Up to 7 days

**S3 Data:**
- **Versioning:** Enabled
- **Lifecycle:** Archive to Glacier after 90 days
- **Cross-region replication:** To us-west-2 (DR region)

### Recovery Procedures

**RTO (Recovery Time Objective):** 1 hour  
**RPO (Recovery Point Objective):** 1 hour

**Scenario 1: Database Corruption**
```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier energy-etl-restored \
  --db-snapshot-identifier energy-etl-backup-2024-03-15

# Verify data integrity
psql -h restored-endpoint -c "SELECT COUNT(*) FROM analytics.market_prices;"

# Update DNS to point to restored instance
```

**Scenario 2: Region Failure**
```bash
# Failover to DR region (us-west-2)
# 1. Promote read replica to primary
# 2. Update API environment variables
# 3. Route53 DNS failover to DR ALB
```

---

## 🎯 Design Decisions

### Why 4 Schemas?

**Alternative:** Single schema with all tables

**Decision:** Separate schemas for clear boundaries

**Benefits:**
- Security (different access controls per schema)
- Clarity (understand data lifecycle)
- Performance (raw_data can be archived separately)
- Recovery (can restore analytics without raw_data)

### Why PostgreSQL?

**Alternatives:** MySQL, MongoDB, Snowflake

**Decision:** PostgreSQL

**Reasons:**
- ACID compliance (financial data requires accuracy)
- Advanced indexing (GiST, GIN for performance)
- Mature ecosystem (tools, connectors)
- Cost-effective (open-source)
- JSON support (flexible raw data storage)

### Why FastAPI?

**Alternatives:** Flask, Django, Express

**Decision:** FastAPI

**Reasons:**
- Automatic OpenAPI documentation
- Pydantic validation (type safety)
- High performance (async support)
- Modern Python (3.7+)
- Growing community

---

## 📚 Technology Stack Summary

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Storage** | AWS S3 | Raw data files |
| **Database** | PostgreSQL 16 | Structured data |
| **Cache** | Redis | API response caching |
| **API** | FastAPI | REST endpoints |
| **Container** | Docker | Application packaging |
| **Orchestration** | ECS Fargate | Container management |
| **Load Balancer** | ALB | Traffic distribution |
| **Monitoring** | CloudWatch, Grafana | Metrics and logs |
| **CI/CD** | GitHub Actions | Automated deployment |
| **Language** | Python 3.11+ | Application code |

---

## 🔗 Related Documentation

- **API Documentation:** `api_documentation.md`
- **Deployment Guide:** `deployment_guide.md`
- **User Guide:** `user_guide.md`
- **Database Schema:** `setup_database.sql`
