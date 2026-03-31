# 👥 User Guide - Energy Trading Settlement Prices System

## Welcome!

This guide helps trading teams, risk managers, and business users access and use settlement price data from the Energy ETL system.

---

## 🎯 Quick Start

### Who This Guide Is For

- **Traders** - Get daily settlement prices for portfolio valuations
- **Risk Analysts** - Access historical data for VaR calculations
- **Excel Users** - Connect directly to data from Excel
- **Power BI Users** - Build dashboards and reports
- **Business Analysts** - Query data for ad-hoc analysis

### What You Can Do

✅ Retrieve daily settlement prices for all energy instruments  
✅ Query historical price trends  
✅ Export data to Excel or CSV  
✅ Connect Power BI for real-time dashboards  
✅ Filter by exchange, date, or instrument  
✅ Calculate daily/monthly price variances  

---

## 📊 Understanding the Data

### What Are Settlement Prices?

**Settlement prices** are the official closing prices published by exchanges (CME, ICE, NYMEX) at the end of each trading day. These prices are used for:

- **Mark-to-Market** - Valuing open positions
- **Margin Calculations** - Determining collateral requirements
- **P&L Calculations** - Daily profit and loss
- **Risk Analytics** - VaR, stress testing, scenario analysis
- **Regulatory Reporting** - Official prices for compliance

### Data Sources

| Exchange | Instruments | Update Time | Delivery |
|----------|-------------|-------------|----------|
| **CME** | Crude Oil (CL), Natural Gas (NG), RBOB Gasoline | 2:30 PM CT | Daily CSV |
| **ICE** | Brent Crude, Gasoil, Power | 4:00 PM GMT | Daily SFTP |
| **NYMEX** | WTI, Heating Oil, Natural Gas | 2:30 PM CT | Daily CSV |

### Data Freshness

- **Published:** 5:00 PM CT (exchanges close, prices finalized)
- **Available in System:** 6:00 PM CT (after ETL processing)
- **Retention:** 10 years of historical data

---

## 🖥️ Accessing Data

### Method 1: Excel Power Query (Recommended for Most Users)

#### Step 1: Open Excel and Get Data

1. Open Excel
2. Go to **Data** → **Get Data** → **From Other Sources** → **From Web**
3. Enter the API URL:
   ```
   http://localhost:8000/api/v1/prices/latest?exchange=CME
   ```
4. Click **OK**

#### Step 2: Authenticate (if required)

For production:
- Select **Advanced**
- Add HTTP header: `Authorization: Bearer YOUR_API_KEY`

#### Step 3: Transform Data

Excel will display JSON data. Click **Into Table** → **Expand Columns**:

- ✅ instrument_name
- ✅ trade_date
- ✅ settlement_price
- ✅ currency
- ✅ contract_month
- ✅ daily_change
- ✅ percent_change

#### Step 4: Refresh Data

- Right-click table → **Refresh**
- Or set automatic refresh: **Data** → **Queries & Connections** → **Properties** → **Refresh every 60 minutes**

#### Example: Get Historical Data for a Specific Instrument

```
http://localhost:8000/api/v1/prices/history/CL.FUT?start_date=2024-01-01&end_date=2024-03-31
```

---

### Method 2: Power BI

#### Step 1: Connect to API

1. Open Power BI Desktop
2. **Get Data** → **Web**
3. Enter URL:
   ```
   http://localhost:8000/api/v1/prices/latest?exchange=CME
   ```
4. Click **OK**

#### Step 2: Transform Data

1. Click **Transform Data**
2. Expand JSON columns
3. Change data types:
   - `settlement_price` → Decimal Number
   - `trade_date` → Date
   - `percent_change` → Percentage

#### Step 3: Create Visualizations

**Sample Report: Daily Price Trends**

1. **Line Chart:**
   - X-axis: `trade_date`
   - Y-axis: `settlement_price`
   - Legend: `instrument_name`

2. **Table:**
   - Columns: `instrument_name`, `settlement_price`, `daily_change`, `percent_change`
   - Conditional formatting on `percent_change` (green/red)

3. **Card Visuals:**
   - Latest settlement price
   - Daily change
   - % change

#### Step 4: Schedule Refresh

1. Publish to Power BI Service
2. Go to **Dataset Settings**
3. Configure **Scheduled Refresh** (every 1 hour)

---

### Method 3: Direct Database Access (Read-Only)

For advanced users who prefer SQL queries.

#### Connection Details

```
Host: energy-etl-prod.xxxxx.us-east-1.rds.amazonaws.com
Port: 5432
Database: energy_production
Username: readonly_user
Password: [Request from IT]
```

#### Sample Queries

**Get Latest Prices for All Instruments:**
```sql
SELECT 
    instrument_name,
    trade_date,
    settlement_price,
    currency,
    daily_change,
    percent_change
FROM analytics.market_prices
WHERE trade_date = CURRENT_DATE - INTERVAL '1 day'
ORDER BY instrument_name;
```

**Historical Prices for WTI Crude:**
```sql
SELECT 
    trade_date,
    settlement_price,
    contract_month
FROM analytics.market_prices
WHERE instrument_id = 'CL.FUT'
  AND trade_date BETWEEN '2024-01-01' AND '2024-03-31'
ORDER BY trade_date;
```

**Monthly Average Prices:**
```sql
SELECT 
    DATE_TRUNC('month', trade_date) AS month,
    instrument_name,
    AVG(settlement_price) AS avg_price,
    MIN(settlement_price) AS min_price,
    MAX(settlement_price) AS max_price
FROM analytics.market_prices
WHERE trade_date >= '2024-01-01'
GROUP BY month, instrument_name
ORDER BY month, instrument_name;
```

**Price Volatility (30-day rolling standard deviation):**
```sql
SELECT 
    trade_date,
    instrument_name,
    settlement_price,
    STDDEV(settlement_price) OVER (
        PARTITION BY instrument_id 
        ORDER BY trade_date 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS volatility_30d
FROM analytics.market_prices
WHERE instrument_id = 'CL.FUT'
  AND trade_date >= '2024-01-01'
ORDER BY trade_date;
```

---

### Method 4: REST API (for Developers)

See full API documentation: `api_documentation.md`

**Quick Example: Get Latest Prices**

```bash
curl -X GET "http://localhost:8000/api/v1/prices/latest?exchange=CME"
```

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "instrument_id": "CL.FUT",
      "instrument_name": "WTI Crude Oil",
      "trade_date": "2024-03-15",
      "settlement_price": 78.45,
      "currency": "USD",
      "daily_change": 0.75,
      "percent_change": 0.96
    }
  ]
}
```

---

## 📈 Common Use Cases

### Use Case 1: Daily Portfolio Valuation

**Goal:** Mark-to-market all open positions using latest settlement prices.

**Excel Workflow:**

1. Load your positions from Excel (columns: `instrument_id`, `quantity`, `buy_price`)
2. Get latest settlement prices via Power Query
3. Merge tables on `instrument_id`
4. Calculate:
   ```excel
   = (settlement_price - buy_price) * quantity
   ```

**Power BI Workflow:**

1. Import positions CSV
2. Connect to `/api/v1/prices/latest`
3. Create relationship on `instrument_id`
4. DAX measure:
   ```dax
   Daily P&L = 
   SUMX(
       Positions,
       Positions[quantity] * (Prices[settlement_price] - Positions[buy_price])
   )
   ```

---

### Use Case 2: Risk Analytics - VaR Calculation

**Goal:** Calculate Value at Risk (VaR) using historical price volatility.

**SQL Query (Historical Volatility):**
```sql
WITH daily_returns AS (
    SELECT 
        trade_date,
        instrument_id,
        settlement_price,
        LAG(settlement_price) OVER (PARTITION BY instrument_id ORDER BY trade_date) AS prev_price,
        (settlement_price / LAG(settlement_price) OVER (PARTITION BY instrument_id ORDER BY trade_date) - 1) AS daily_return
    FROM analytics.market_prices
    WHERE trade_date >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    instrument_id,
    STDDEV(daily_return) AS daily_volatility,
    STDDEV(daily_return) * SQRT(252) AS annual_volatility,
    PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY daily_return) AS var_95
FROM daily_returns
WHERE daily_return IS NOT NULL
GROUP BY instrument_id;
```

---

### Use Case 3: Price Variance Analysis

**Goal:** Identify unusual price movements (>5% daily change).

**Power BI Report:**

1. Connect to `/api/v1/prices?start_date=2024-01-01&end_date=2024-03-31`
2. Filter: `percent_change > 5 OR percent_change < -5`
3. Visual: Table with conditional formatting
4. Slicers: `exchange`, `instrument_name`, `trade_date`

**Excel PivotTable:**

1. Load data via Power Query
2. Create PivotTable:
   - Rows: `trade_date`, `instrument_name`
   - Values: `settlement_price`, `percent_change`
3. Filter: `percent_change > 5`

---

### Use Case 4: Forward Curve Analysis

**Goal:** Visualize the forward curve (settlement prices across contract months).

**SQL Query:**
```sql
SELECT 
    contract_month,
    settlement_price
FROM analytics.market_prices
WHERE instrument_id = 'CL.FUT'
  AND trade_date = '2024-03-15'
ORDER BY contract_month;
```

**Excel Chart:**

1. X-axis: Contract Month (Apr-24, May-24, Jun-24...)
2. Y-axis: Settlement Price
3. Chart Type: Line Chart

**Power BI Visual:**

- Line chart with `contract_month` on X-axis
- Date slicer to compare forward curves on different dates

---

## 🔍 Understanding Data Fields

### Main Data Table: `analytics.market_prices`

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `instrument_id` | Text | Unique instrument code | `CL.FUT` |
| `instrument_name` | Text | Human-readable name | `WTI Crude Oil` |
| `trade_date` | Date | Date of settlement | `2024-03-15` |
| `settlement_price` | Decimal | Official closing price | `78.45` |
| `currency` | Text | Price denomination | `USD` |
| `exchange` | Text | Exchange name | `CME` |
| `contract_month` | Text | Delivery month | `2024-05` |
| `daily_change` | Decimal | Price change vs. previous day | `0.75` |
| `percent_change` | Decimal | % change vs. previous day | `0.96` |
| `volume` | Integer | Trading volume | `245000` |
| `open_interest` | Integer | Open contracts | `1234567` |
| `data_quality_flag` | Text | Quality indicator | `VALID` |

### Instrument IDs

| Code | Name | Exchange | Unit |
|------|------|----------|------|
| `CL.FUT` | WTI Crude Oil | CME/NYMEX | USD per barrel |
| `NG.FUT` | Natural Gas | CME | USD per MMBtu |
| `RB.FUT` | RBOB Gasoline | CME | USD per gallon |
| `HO.FUT` | Heating Oil | CME | USD per gallon |
| `BRN.FUT` | Brent Crude | ICE | USD per barrel |
| `GO.FUT` | Gasoil | ICE | USD per tonne |

---

## ⚠️ Data Quality Flags

| Flag | Meaning | Action |
|------|---------|--------|
| `VALID` | All quality checks passed | Safe to use |
| `LATE_ARRIVAL` | Data arrived >24 hours late | Use with caution |
| `MISSING_VOLUME` | Volume data unavailable | Price valid, volume unknown |
| `ESTIMATED` | Price estimated from related contracts | Verify before use |
| `CORRECTED` | Exchange issued price correction | Updated value |

**Check data quality:**
```sql
SELECT trade_date, instrument_id, data_quality_flag
FROM analytics.market_prices
WHERE data_quality_flag != 'VALID'
  AND trade_date >= CURRENT_DATE - INTERVAL '7 days';
```

---

## 💡 Best Practices

### 1. Date Handling

✅ **Do:**
- Use YYYY-MM-DD format (`2024-03-15`)
- Account for weekends and holidays (no trading data)
- Use `trade_date` field (not `ingestion_timestamp`)

❌ **Don't:**
- Use today's date (prices lag by 1 day)
- Forget timezone differences (exchanges publish in CT/GMT)

### 2. Performance

✅ **Do:**
- Limit date ranges to necessary periods
- Use indexes (instrument_id, trade_date)
- Cache frequently accessed data in Excel

❌ **Don't:**
- Query all historical data without filters
- Refresh Power BI every minute (hourly is sufficient)

### 3. Data Validation

✅ **Do:**
- Check `data_quality_flag` before critical calculations
- Verify settlement prices against exchange websites
- Monitor for missing days (holidays, system outages)

❌ **Don't:**
- Assume all prices are final (corrections happen)
- Ignore quality flags

---

## 📞 Getting Help

### Common Questions

**Q: Why don't I see today's prices?**  
A: Settlement prices are published end-of-day. Today's data will be available tomorrow morning.

**Q: Why are there multiple prices for the same instrument?**  
A: Different contract months. Filter by `contract_month` to get specific contract.

**Q: What if I need intraday prices?**  
A: This system only provides settlement prices. Contact market data team for intraday feeds.

**Q: Can I get options data?**  
A: Not yet. Currently only futures settlement prices are supported.

### Support Channels

- **Excel/Power BI Issues:** bi-support@veraxion.com
- **Data Quality Questions:** data-quality@veraxion.com  
- **API Access Requests:** api-access@veraxion.com
- **General Questions:** #energy-data-help (Slack)

### Training Sessions

Monthly training available:
- **Excel Power Query:** First Tuesday, 2 PM
- **Power BI Dashboards:** First Thursday, 2 PM
- **SQL for Analysts:** Second Wednesday, 2 PM

Register: learning@veraxion.com

---

## 📚 Additional Resources

- **API Documentation:** `api_documentation.md`
- **Troubleshooting Guide:** `troubleshooting.md`
- **Energy Market Concepts:** `energy_market_concepts.md`
- **Exchange Websites:**
  - CME Group: https://www.cmegroup.com/
  - ICE: https://www.theice.com/
  - NYMEX: https://www.cmegroup.com/markets/energy.html

---

## 🎓 Sample Excel Workbook

Download ready-to-use Excel template: `energy-prices-template.xlsx`

Includes:
- Pre-configured Power Query connections
- PivotTable templates
- Price variance calculators
- Forward curve charts
- VaR calculation worksheets

Request from: data-templates@veraxion.com
