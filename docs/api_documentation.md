# 📡 API Documentation

## Overview

The Energy ETL API provides RESTful endpoints for accessing settlement price data from energy exchanges. Built with FastAPI, it offers high performance, automatic validation, and interactive documentation.

**Base URL:** `http://localhost:8000` (development)  
**Production URL:** `https://api.veraxion.com/energy` (to be configured)

---

## 🔐 Authentication

### API Key Authentication (Production)
```http
GET /api/v1/prices
Authorization: Bearer YOUR_API_KEY_HERE
```

### Development Mode
No authentication required for local development.

---

## 📋 Core Endpoints

### 1. Get Settlement Prices

**Endpoint:** `GET /api/v1/prices`

**Description:** Retrieve settlement prices filtered by date, exchange, instrument, or contract month.

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `trade_date` | string | No | Filter by specific trade date (YYYY-MM-DD) | `2024-03-15` |
| `start_date` | string | No | Start of date range | `2024-01-01` |
| `end_date` | string | No | End of date range | `2024-03-31` |
| `exchange` | string | No | Exchange name (CME, ICE, NYMEX) | `CME` |
| `instrument_id` | string | No | Specific instrument code | `CL.FUT` |
| `contract_month` | string | No | Contract delivery month | `2024-05` |
| `limit` | integer | No | Max records to return (default: 100, max: 1000) | `500` |
| `offset` | integer | No | Pagination offset (default: 0) | `100` |

**Example Request:**
```bash
curl -X GET "http://localhost:8000/api/v1/prices?trade_date=2024-03-15&exchange=CME&limit=50"
```

**Example Response:**
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
      "exchange": "CME",
      "contract_month": "2024-05",
      "daily_change": 0.75,
      "percent_change": 0.96,
      "volume": 245000,
      "open_interest": 1234567
    },
    {
      "instrument_id": "NG.FUT",
      "instrument_name": "Natural Gas",
      "trade_date": "2024-03-15",
      "settlement_price": 2.45,
      "currency": "USD",
      "exchange": "CME",
      "contract_month": "2024-04",
      "daily_change": -0.05,
      "percent_change": -2.0,
      "volume": 189000,
      "open_interest": 987654
    }
  ],
  "metadata": {
    "total_records": 2,
    "page": 1,
    "limit": 50,
    "timestamp": "2024-03-15T10:30:00Z"
  }
}
```

---

### 2. Get Available Instruments

**Endpoint:** `GET /api/v1/instruments`

**Description:** List all available instruments with their metadata.

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `exchange` | string | No | Filter by exchange | `ICE` |
| `commodity_type` | string | No | Filter by type (CRUDE, GAS, POWER, COAL) | `CRUDE` |

**Example Request:**
```bash
curl -X GET "http://localhost:8000/api/v1/instruments?exchange=CME"
```

**Example Response:**
```json
{
  "status": "success",
  "data": [
    {
      "instrument_id": "CL.FUT",
      "instrument_name": "WTI Crude Oil",
      "exchange": "CME",
      "commodity_type": "CRUDE",
      "contract_size": "1,000 barrels",
      "price_unit": "USD per barrel",
      "tick_size": 0.01,
      "trading_hours": "18:00-17:00 CT",
      "last_trading_day": "3rd business day prior to 25th calendar day"
    }
  ]
}
```

---

### 3. Get Price History for Instrument

**Endpoint:** `GET /api/v1/prices/history/{instrument_id}`

**Description:** Get historical price data for a specific instrument.

**Path Parameters:**
- `instrument_id` (string): The instrument identifier (e.g., `CL.FUT`)

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `start_date` | string | Yes | Start date (YYYY-MM-DD) | `2024-01-01` |
| `end_date` | string | Yes | End date (YYYY-MM-DD) | `2024-03-31` |
| `contract_month` | string | No | Specific contract month | `2024-05` |

**Example Request:**
```bash
curl -X GET "http://localhost:8000/api/v1/prices/history/CL.FUT?start_date=2024-01-01&end_date=2024-03-31"
```

**Example Response:**
```json
{
  "status": "success",
  "instrument_id": "CL.FUT",
  "instrument_name": "WTI Crude Oil",
  "data": [
    {
      "trade_date": "2024-01-02",
      "settlement_price": 72.15,
      "contract_month": "2024-02",
      "volume": 234000,
      "open_interest": 1123456
    },
    {
      "trade_date": "2024-01-03",
      "settlement_price": 72.85,
      "contract_month": "2024-02",
      "volume": 245000,
      "open_interest": 1134567
    }
  ],
  "summary": {
    "total_records": 2,
    "date_range": {
      "start": "2024-01-02",
      "end": "2024-01-03"
    },
    "price_range": {
      "min": 72.15,
      "max": 72.85,
      "average": 72.50
    }
  }
}
```

---

### 4. Get Latest Prices

**Endpoint:** `GET /api/v1/prices/latest`

**Description:** Get the most recent settlement prices for all instruments.

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `exchange` | string | No | Filter by exchange | `CME` |
| `commodity_type` | string | No | Filter by commodity type | `CRUDE` |

**Example Request:**
```bash
curl -X GET "http://localhost:8000/api/v1/prices/latest?exchange=CME"
```

**Example Response:**
```json
{
  "status": "success",
  "data": [
    {
      "instrument_id": "CL.FUT",
      "instrument_name": "WTI Crude Oil",
      "trade_date": "2024-03-15",
      "settlement_price": 78.45,
      "contract_month": "2024-05",
      "daily_change": 0.75,
      "percent_change": 0.96
    }
  ],
  "metadata": {
    "as_of_date": "2024-03-15",
    "total_instruments": 1
  }
}
```

---

### 5. Get Price Statistics

**Endpoint:** `GET /api/v1/prices/stats/{instrument_id}`

**Description:** Get statistical analysis for an instrument over a date range.

**Path Parameters:**
- `instrument_id` (string): The instrument identifier

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `start_date` | string | Yes | Start date | `2024-01-01` |
| `end_date` | string | Yes | End date | `2024-03-31` |

**Example Response:**
```json
{
  "status": "success",
  "instrument_id": "CL.FUT",
  "date_range": {
    "start": "2024-01-01",
    "end": "2024-03-31"
  },
  "statistics": {
    "mean_price": 75.23,
    "median_price": 75.10,
    "std_deviation": 3.45,
    "min_price": 68.50,
    "max_price": 82.30,
    "price_range": 13.80,
    "total_records": 63,
    "volatility_30d": 0.18,
    "avg_daily_volume": 234500
  }
}
```

---

### 6. Health Check

**Endpoint:** `GET /health`

**Description:** Check API and database connectivity status.

**Example Request:**
```bash
curl -X GET "http://localhost:8000/health"
```

**Example Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-03-15T10:30:00Z",
  "version": "1.0.0",
  "checks": {
    "database": "connected",
    "last_data_update": "2024-03-15T06:00:00Z",
    "total_records": 1234567
  }
}
```

---

### 7. API Documentation

**Endpoint:** `GET /docs`

**Description:** Interactive Swagger UI documentation.

**Endpoint:** `GET /redoc`

**Description:** Alternative ReDoc documentation interface.

---

## 📊 Data Quality Endpoints

### 8. Get Data Quality Report

**Endpoint:** `GET /api/v1/quality/report`

**Description:** Retrieve data quality metrics and validation results.

**Query Parameters:**

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `trade_date` | string | No | Specific date | `2024-03-15` |
| `start_date` | string | No | Start of range | `2024-03-01` |
| `end_date` | string | No | End of range | `2024-03-31` |

**Example Response:**
```json
{
  "status": "success",
  "date_range": {
    "start": "2024-03-01",
    "end": "2024-03-31"
  },
  "quality_metrics": {
    "total_records": 12000,
    "valid_records": 11950,
    "invalid_records": 50,
    "completeness_score": 99.58,
    "duplicate_records": 5,
    "null_prices": 15,
    "out_of_range_prices": 30
  },
  "issues": [
    {
      "date": "2024-03-10",
      "issue_type": "null_price",
      "instrument_id": "NG.FUT",
      "severity": "high"
    }
  ]
}
```

---

## 🔄 Batch Operations

### 9. Bulk Price Export

**Endpoint:** `POST /api/v1/prices/export`

**Description:** Export large datasets to CSV/Excel format.

**Request Body:**
```json
{
  "start_date": "2024-01-01",
  "end_date": "2024-03-31",
  "exchange": "CME",
  "format": "csv",
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "status": "accepted",
  "job_id": "export_12345",
  "message": "Export job queued. You will receive an email when complete.",
  "estimated_time": "5 minutes"
}
```

---

## ⚠️ Error Responses

### Standard Error Format

```json
{
  "status": "error",
  "error": {
    "code": "INVALID_DATE_FORMAT",
    "message": "Invalid date format. Expected YYYY-MM-DD",
    "details": {
      "field": "trade_date",
      "provided": "15-03-2024",
      "expected": "2024-03-15"
    }
  },
  "timestamp": "2024-03-15T10:30:00Z"
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_DATE_FORMAT` | 400 | Date format is incorrect |
| `INVALID_PARAMETER` | 400 | Invalid query parameter |
| `RESOURCE_NOT_FOUND` | 404 | Instrument or data not found |
| `UNAUTHORIZED` | 401 | Invalid or missing API key |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |
| `DATABASE_ERROR` | 503 | Database connectivity issue |

---

## 🔢 Rate Limiting

**Development:** No rate limits  
**Production:** 
- 100 requests per minute per API key
- 1000 requests per hour per API key

**Rate Limit Headers:**
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1710504600
```

---

## 📱 Client Examples

### Python (using requests)

```python
import requests

# Get latest prices
response = requests.get(
    "http://localhost:8000/api/v1/prices/latest",
    params={"exchange": "CME"}
)

if response.status_code == 200:
    data = response.json()
    for price in data['data']:
        print(f"{price['instrument_name']}: ${price['settlement_price']}")
```

### Excel Power Query

```m
let
    Source = Json.Document(
        Web.Contents(
            "http://localhost:8000/api/v1/prices",
            [Query=[trade_date="2024-03-15", exchange="CME"]]
        )
    ),
    data = Source[data],
    ToTable = Table.FromList(data, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    Expanded = Table.ExpandRecordColumn(ToTable, "Column1", 
        {"instrument_name", "trade_date", "settlement_price", "currency"})
in
    Expanded
```

### Power BI

1. Get Data → Web
2. Enter URL: `http://localhost:8000/api/v1/prices/latest?exchange=CME`
3. Expand JSON columns
4. Set refresh schedule

### cURL

```bash
# Get prices for specific date
curl -X GET "http://localhost:8000/api/v1/prices?trade_date=2024-03-15" \
  -H "Accept: application/json"

# Get price history
curl -X GET "http://localhost:8000/api/v1/prices/history/CL.FUT?start_date=2024-01-01&end_date=2024-03-31"

# Health check
curl -X GET "http://localhost:8000/health"
```

---

## 🌐 WebSocket Support (Future)

Real-time price updates via WebSocket connection:

```javascript
const ws = new WebSocket('ws://localhost:8000/ws/prices');

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Price update:', data);
};
```

---

## 📚 Additional Resources

- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **OpenAPI Schema:** http://localhost:8000/openapi.json
- **User Guide:** See `user_guide.md`
- **Troubleshooting:** See `troubleshooting.md`

---

## 📞 Support

For API issues or questions:
- **Email:** api-support@veraxion.com
- **Slack:** #energy-etl-support
- **Documentation:** https://docs.veraxion.com/energy-etl
