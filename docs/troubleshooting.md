# 🔧 Troubleshooting Guide

## Overview

This guide helps you diagnose and resolve common issues with the Energy ETL system.

---

## 🚦 Quick Diagnostics

### System Health Check

```bash
# 1. Check API status
curl http://localhost:8000/health

# 2. Check database connectivity
docker-compose exec postgres psql -U learner -d energy_learning -c "SELECT 1;"

# 3. Check ETL pipeline logs
docker-compose logs -f --tail=100

# 4. Check disk space
df -h

# 5. Check running processes
docker-compose ps
```

**Expected Healthy Response:**
```json
{
  "status": "healthy",
  "database": "connected",
  "last_data_update": "2024-03-15T06:00:00Z",
  "total_records": 1234567
}
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Database Connection Failed

**Symptoms:**
```
psycopg2.OperationalError: could not connect to server: Connection refused
```

**Diagnosis:**
```bash
# Check if PostgreSQL is running
docker-compose ps

# Check PostgreSQL logs
docker-compose logs postgres | tail -50

# Verify port availability
netstat -an | grep 5432
```

**Solutions:**

**Solution A: Database Not Started**
```bash
# Start PostgreSQL
docker-compose up -d postgres

# Wait 10 seconds and verify
docker-compose ps
```

**Solution B: Port Conflict**
```bash
# Check what's using port 5432
netstat -tulpn | grep 5432

# Option 1: Stop conflicting service
sudo systemctl stop postgresql

# Option 2: Change port in docker-compose.yaml
# Edit: ports: "5433:5432"
# Update connection string in .env
```

**Solution C: Connection Pool Exhausted**
```bash
# Check active connections
docker-compose exec postgres psql -U learner -d energy_learning -c "SELECT count(*) FROM pg_stat_activity;"

# Kill idle connections
docker-compose exec postgres psql -U learner -d energy_learning -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'idle' AND state_change < now() - interval '10 minutes';
"

# Increase pool size in src/database/connection.py
# pool_size=20 -> pool_size=50
```

---

### Issue 2: API Returns 503 Service Unavailable

**Symptoms:**
```bash
curl http://localhost:8000/api/v1/prices
# Response: {"detail": "Service Unavailable"}
```

**Diagnosis:**
```bash
# Check if API is running
curl http://localhost:8000/health

# Check API logs
docker-compose logs api --tail=100

# Check system resources
docker stats
```

**Solutions:**

**Solution A: API Not Started**
```bash
# Start API service
docker-compose up -d api

# Or if running locally
python -m uvicorn src.api.main:app --reload
```

**Solution B: Database Connection Failed**
See Issue 1 solutions.

**Solution C: Out of Memory**
```bash
# Check memory usage
free -h
docker stats

# Restart API with more memory
docker-compose down
# Edit docker-compose.yaml: memory: 2g
docker-compose up -d
```

---

### Issue 3: Missing Data for Specific Date

**Symptoms:**
```bash
curl "http://localhost:8000/api/v1/prices?trade_date=2024-03-15"
# Response: {"data": []}
```

**Diagnosis:**
```sql
-- Check if data exists in raw_data
SELECT COUNT(*) 
FROM raw_data.settlement_prices_raw 
WHERE price_date = '2024-03-15';

-- Check if data exists in staging
SELECT COUNT(*) 
FROM staging.settlement_prices_staging 
WHERE trade_date = '2024-03-15';

-- Check if data exists in analytics
SELECT COUNT(*) 
FROM analytics.market_prices 
WHERE trade_date = '2024-03-15';

-- Check audit logs for errors
SELECT * 
FROM audit.etl_run_log 
WHERE run_date = '2024-03-15' 
ORDER BY start_timestamp DESC;
```

**Solutions:**

**Solution A: Weekend or Holiday**
```sql
-- Check if date is weekend
SELECT EXTRACT(DOW FROM DATE '2024-03-15');
-- Returns 0 (Sunday) or 6 (Saturday) = no trading

-- Check holiday calendar
SELECT * FROM analytics.trading_calendar 
WHERE calendar_date = '2024-03-15';
```

**Solution B: Data Not Yet Loaded**
```bash
# Check S3 bucket for raw file
aws s3 ls s3://energy-etl-raw-data/ | grep "2024-03-15"

# Manually trigger ETL pipeline
python src/etl/ingest_settlement_prices.py --date 2024-03-15
```

**Solution C: Data Quality Check Failed**
```sql
-- Check rejection reasons
SELECT * 
FROM audit.data_quality_checks 
WHERE trade_date = '2024-03-15' 
  AND check_status = 'FAILED';

-- Bypass quality check (if acceptable)
UPDATE staging.settlement_prices_staging
SET validation_status = 'PASSED'
WHERE trade_date = '2024-03-15';

-- Re-run transformation
python src/etl/transform_to_analytics.py --date 2024-03-15
```

---

### Issue 4: Slow API Response Times

**Symptoms:**
```bash
# Response takes >5 seconds
time curl "http://localhost:8000/api/v1/prices?start_date=2024-01-01&end_date=2024-12-31"
```

**Diagnosis:**
```sql
-- Check query performance
EXPLAIN ANALYZE
SELECT * FROM analytics.market_prices
WHERE trade_date BETWEEN '2024-01-01' AND '2024-12-31';

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE tablename = 'market_prices';

-- Check table statistics
SELECT 
    relname AS table_name,
    n_live_tup AS row_count,
    n_dead_tup AS dead_rows
FROM pg_stat_user_tables
WHERE relname = 'market_prices';
```

**Solutions:**

**Solution A: Missing Indexes**
```sql
-- Add missing indexes
CREATE INDEX CONCURRENTLY idx_market_prices_trade_date 
ON analytics.market_prices(trade_date);

CREATE INDEX CONCURRENTLY idx_market_prices_instrument_trade_date 
ON analytics.market_prices(instrument_id, trade_date);

CREATE INDEX CONCURRENTLY idx_market_prices_exchange 
ON analytics.market_prices(exchange);
```

**Solution B: Table Needs Vacuuming**
```sql
-- Vacuum and analyze
VACUUM ANALYZE analytics.market_prices;

-- Check improvement
EXPLAIN ANALYZE
SELECT * FROM analytics.market_prices
WHERE trade_date = '2024-03-15';
```

**Solution C: Too Many Results (Add Pagination)**
```bash
# Use limit/offset
curl "http://localhost:8000/api/v1/prices?start_date=2024-01-01&limit=100&offset=0"
```

**Solution D: Enable Caching**
```python
# Add Redis caching in src/api/main.py
from fastapi_cache import FastAPICache
from fastapi_cache.decorator import cache

@app.get("/api/v1/prices/latest")
@cache(expire=3600)  # Cache for 1 hour
async def get_latest_prices():
    ...
```

---

### Issue 5: ETL Pipeline Fails

**Symptoms:**
```bash
python src/etl/ingest_settlement_prices.py
# Error: FileNotFoundError: CSV file not found
```

**Diagnosis:**
```bash
# Check ETL logs
tail -100 logs/etl_pipeline.log

# Check audit table
psql -U learner -d energy_learning -c "
SELECT * FROM audit.etl_run_log 
WHERE run_status = 'FAILED' 
ORDER BY start_timestamp DESC 
LIMIT 10;
"
```

**Solutions:**

**Solution A: Missing Input File**
```bash
# Check S3 bucket
aws s3 ls s3://energy-etl-raw-data/

# Download file manually
aws s3 cp s3://energy-etl-raw-data/CME_settlements_2024-03-15.csv ./data/raw/

# Re-run pipeline
python src/etl/ingest_settlement_prices.py --file ./data/raw/CME_settlements_2024-03-15.csv
```

**Solution B: Schema Validation Failed**
```python
# Check error message
# Expected columns: ['instrument_id', 'trade_date', 'settlement_price', ...]
# Found: ['InstrumentID', 'TradeDate', 'Price', ...]

# Update column mapping in src/etl/config.py
COLUMN_MAPPING = {
    'InstrumentID': 'instrument_id',
    'TradeDate': 'trade_date',
    'Price': 'settlement_price'
}
```

**Solution C: Database Lock**
```sql
-- Check for locks
SELECT 
    pg_stat_activity.pid,
    pg_stat_activity.query,
    pg_locks.mode,
    pg_locks.granted
FROM pg_stat_activity
JOIN pg_locks ON pg_stat_activity.pid = pg_locks.pid
WHERE pg_locks.granted = false;

-- Kill blocking query
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid = <PID>;
```

---

### Issue 6: Duplicate Records

**Symptoms:**
```sql
SELECT instrument_id, trade_date, COUNT(*)
FROM analytics.market_prices
GROUP BY instrument_id, trade_date
HAVING COUNT(*) > 1;
```

**Diagnosis:**
```sql
-- Find duplicates with details
SELECT * FROM analytics.market_prices
WHERE (instrument_id, trade_date) IN (
    SELECT instrument_id, trade_date
    FROM analytics.market_prices
    GROUP BY instrument_id, trade_date
    HAVING COUNT(*) > 1
)
ORDER BY instrument_id, trade_date;

-- Check source
SELECT source_file_name, COUNT(*)
FROM raw_data.settlement_prices_raw
WHERE price_date = '2024-03-15'
GROUP BY source_file_name;
```

**Solutions:**

**Solution A: Remove Duplicates (Keep Latest)**
```sql
-- Delete duplicates, keep most recent ingestion
DELETE FROM analytics.market_prices a
WHERE a.price_id NOT IN (
    SELECT MAX(price_id)
    FROM analytics.market_prices b
    WHERE a.instrument_id = b.instrument_id
      AND a.trade_date = b.trade_date
);
```

**Solution B: Prevent Future Duplicates**
```sql
-- Add unique constraint
ALTER TABLE analytics.market_prices
ADD CONSTRAINT unique_instrument_trade_date 
UNIQUE (instrument_id, trade_date, contract_month);
```

**Solution C: Fix ETL Deduplication Logic**
```python
# Update src/etl/transform.py
df_deduplicated = df.drop_duplicates(
    subset=['instrument_id', 'trade_date', 'contract_month'],
    keep='last'  # Keep most recent
)
```

---

### Issue 7: Data Quality Flags

**Symptoms:**
```sql
SELECT trade_date, COUNT(*) 
FROM analytics.market_prices 
WHERE data_quality_flag != 'VALID'
GROUP BY trade_date;
```

**Diagnosis:**
```sql
-- Detailed quality issue breakdown
SELECT 
    data_quality_flag,
    COUNT(*) as count,
    MIN(trade_date) as first_occurrence,
    MAX(trade_date) as last_occurrence
FROM analytics.market_prices
WHERE data_quality_flag != 'VALID'
GROUP BY data_quality_flag;

-- Check specific issues
SELECT * FROM audit.data_quality_checks
WHERE check_status = 'FAILED'
  AND trade_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY trade_date DESC;
```

**Solutions:**

**Solution A: Missing Volume Data**
```sql
-- Acceptable if price is valid
-- Update flag to VALID_NO_VOLUME
UPDATE analytics.market_prices
SET data_quality_flag = 'VALID_NO_VOLUME'
WHERE data_quality_flag = 'MISSING_VOLUME'
  AND settlement_price IS NOT NULL;
```

**Solution B: Outlier Prices**
```sql
-- Review outliers
SELECT instrument_id, trade_date, settlement_price,
       LAG(settlement_price) OVER (PARTITION BY instrument_id ORDER BY trade_date) as prev_price,
       (settlement_price / LAG(settlement_price) OVER (PARTITION BY instrument_id ORDER BY trade_date) - 1) * 100 as pct_change
FROM analytics.market_prices
WHERE data_quality_flag = 'OUTLIER'
ORDER BY ABS(pct_change) DESC;

-- If valid (e.g., major news event), update flag
UPDATE analytics.market_prices
SET data_quality_flag = 'VALID',
    quality_notes = 'Confirmed outlier due to market event'
WHERE instrument_id = 'CL.FUT' 
  AND trade_date = '2024-03-15';
```

**Solution C: Late Arrival**
```sql
-- Late data is still valid
UPDATE analytics.market_prices
SET data_quality_flag = 'VALID'
WHERE data_quality_flag = 'LATE_ARRIVAL'
  AND settlement_price IS NOT NULL
  AND trade_date >= CURRENT_DATE - INTERVAL '30 days';
```

---

## 🔍 Debugging Tools

### Enable Debug Logging

```python
# src/config/logging_config.py
import logging

logging.basicConfig(
    level=logging.DEBUG,  # Change from INFO to DEBUG
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

### SQL Query Profiling

```sql
-- Enable query timing
\timing on

-- Explain query plan
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM analytics.market_prices
WHERE trade_date = '2024-03-15';

-- Check slow queries
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    max_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

### API Request Logging

```python
# Add middleware in src/api/main.py
import time
from fastapi import Request

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    logger.info(
        f"{request.method} {request.url.path} "
        f"completed in {process_time:.2f}s "
        f"status={response.status_code}"
    )
    
    return response
```

---

## 📊 Monitoring Dashboards

### CloudWatch Metrics to Watch

1. **API Latency** - Should be < 200ms (p50), < 1s (p99)
2. **Error Rate** - Should be < 1%
3. **Database Connections** - Should be < 80% of pool
4. **CPU Utilization** - Should be < 70%
5. **Memory Usage** - Should be < 80%

### Set Up Alerts

```bash
# CPU alert
aws cloudwatch put-metric-alarm \
  --alarm-name high-cpu \
  --metric-name CPUUtilization \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold

# Error rate alert
aws cloudwatch put-metric-alarm \
  --alarm-name high-errors \
  --metric-name 5XXError \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

---

## 🆘 Escalation Procedures

### Level 1: Self-Service (You)
- Check this troubleshooting guide
- Review logs and error messages
- Verify configuration

### Level 2: Team Support
- **Slack:** #energy-etl-support
- **Email:** etl-support@veraxion.com
- **Response Time:** 2 business hours

### Level 3: On-Call Engineer
- **Phone:** +1-xxx-xxx-xxxx
- **Use For:** Production outages only
- **Response Time:** 15 minutes

### Level 4: Vendor Support
- **AWS Support:** Submit ticket for infrastructure issues
- **Exchange Support:** Contact CME/ICE for data issues

---

## 📝 Reporting Bugs

When reporting issues, include:

1. **Error message** (full stack trace)
2. **Steps to reproduce**
3. **Expected vs actual behavior**
4. **Timestamp** of issue
5. **Logs** (attach relevant sections)
6. **Environment** (dev/staging/production)

**Template:**
```
Title: [Component] Brief description

Environment: Production
Timestamp: 2024-03-15 14:30:00 UTC

Issue:
Describe what went wrong

Steps to Reproduce:
1. Step one
2. Step two
3. ...

Expected: What should happen
Actual: What actually happened

Logs:
<paste relevant logs>

Impact: High/Medium/Low
```

---

## 🔗 Additional Resources

- **API Documentation:** `api_documentation.md`
- **User Guide:** `user_guide.md`
- **Deployment Guide:** `deployment_guide.md`
- **Runbook:** `docs/runbook.md` (for operators)

---

## 💡 Pro Tips

1. **Always check logs first** - 90% of issues are revealed in logs
2. **Reproduce in dev** - Test fixes before applying to production
3. **Document workarounds** - Help the next person
4. **Update this guide** - Add new issues you discover
5. **Monitor after fixes** - Ensure issue doesn't recur
