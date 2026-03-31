# ⚡ Energy Markets Fundamentals

## 📚 Complete Guide to Understanding Energy Trading Data

This document explains the energy markets, trading concepts, and data structures you're working with in this ETL system.

---

## 🌍 What Are Energy Markets?

### Overview

**Energy markets** are platforms where energy commodities (crude oil, natural gas, electricity, refined products) are bought and sold for physical delivery or financial settlement.

### Why Energy Markets Exist

1. **Price Discovery** - Transparent pricing through supply/demand
2. **Risk Management** - Hedging against price volatility
3. **Physical Delivery** - Ensuring energy supply for consumers
4. **Speculation** - Profiting from price movements
5. **Arbitrage** - Exploiting price differences across markets

---

## 🛢️ Energy Commodities

### 1. Crude Oil

**What It Is:**  
Unrefined petroleum extracted from underground reservoirs.

**Main Benchmarks:**

| Product | Exchange | Symbol | Description | Pricing Unit |
|---------|----------|--------|-------------|--------------|
| **WTI (West Texas Intermediate)** | CME/NYMEX | CL | Light, sweet crude from US | USD per barrel |
| **Brent Crude** | ICE | BRN | North Sea crude, global benchmark | USD per barrel |
| **Dubai/Oman** | DME | DME | Middle East crude | USD per barrel |

**Key Facts:**
- **Contract Size:** 1,000 barrels (WTI), 1,000 barrels (Brent)
- **Tick Size:** $0.01 per barrel ($10 per contract)
- **Trading Hours:** Nearly 24 hours (electronic)
- **Physical Delivery:** Cushing, Oklahoma (WTI), North Sea terminals (Brent)

**Why Prices Move:**
- OPEC+ production decisions
- US shale production levels
- Geopolitical events (wars, sanctions)
- Economic growth/recession
- Refinery demand
- Strategic petroleum reserve releases

**Example:**  
If WTI crude settles at $78.45/barrel, a trader with a long position of 10 contracts owns the right to 10,000 barrels at $78.45 each = $784,500 total value.

---

### 2. Natural Gas

**What It Is:**  
Naturally occurring hydrocarbon gas used for heating, electricity generation, and industrial processes.

**Main Contracts:**

| Product | Exchange | Symbol | Description | Pricing Unit |
|---------|----------|--------|-------------|--------------|
| **Henry Hub Natural Gas** | CME/NYMEX | NG | US benchmark | USD per MMBtu |
| **UK NBP Gas** | ICE | NBP | UK/Europe benchmark | GBP per therm |
| **Dutch TTF Gas** | ICE | TTF | European benchmark | EUR per MWh |

**Key Facts:**
- **Contract Size:** 10,000 MMBtu (million British thermal units)
- **Tick Size:** $0.001 per MMBtu ($10 per contract)
- **Seasonality:** High demand in winter (heating), summer (cooling/power gen)
- **Storage:** Underground storage crucial for supply management

**Why Prices Move:**
- Weather (cold winter = high demand, hot summer = power demand)
- Storage levels (weekly EIA reports)
- LNG exports
- Pipeline capacity constraints
- Coal-to-gas switching in power generation

**Example:**  
If natural gas settles at $2.45/MMBtu, one contract is worth 10,000 × $2.45 = $24,500.

---

### 3. Refined Products

#### A. RBOB Gasoline

**What It Is:**  
Reformulated Blendstock for Oxygenate Blending (gasoline before ethanol added).

- **Exchange:** CME/NYMEX
- **Symbol:** RB
- **Contract Size:** 42,000 gallons (1,000 barrels)
- **Pricing:** USD per gallon
- **Seasonality:** High demand in summer driving season

#### B. Heating Oil / Diesel

**What It Is:**  
Distillate fuel oil used for heating and diesel engines.

- **Exchange:** CME/NYMEX
- **Symbol:** HO
- **Contract Size:** 42,000 gallons (1,000 barrels)
- **Pricing:** USD per gallon
- **Seasonality:** High demand in winter

#### C. Jet Fuel

- **Exchange:** ICE
- **Use:** Aviation fuel
- **Correlation:** Closely tracks crude oil and heating oil

---

### 4. Power/Electricity

**What It Is:**  
Electricity traded for delivery at specific locations (nodes) and times.

**Main Hubs:**

| Region | Hub | Description |
|--------|-----|-------------|
| **PJM** | Western Hub | Mid-Atlantic/Midwest US |
| **ERCOT** | North Hub | Texas |
| **CAISO** | SP15 | Southern California |
| **NYISO** | Zone A | New York City |

**Key Facts:**
- **Cannot be stored** (must balance supply/demand in real-time)
- **Extreme volatility** (can spike 100x during shortages)
- **Locational pricing** (transmission constraints create price differences)
- **Time-based products:** Peak (6 AM-10 PM weekdays), Off-Peak

**Why Prices Move:**
- Demand (weather, time of day, day of week)
- Generation availability (outages, renewable output)
- Fuel prices (natural gas, coal)
- Transmission constraints

---

## 📊 Market Participants

### 1. Hedgers (Commercial Users)

**Who:** Airlines, utilities, refiners, oil producers  
**Goal:** Lock in prices to reduce business risk  
**Example:** An airline buys jet fuel futures to protect against rising prices.

### 2. Speculators

**Who:** Hedge funds, proprietary traders, CTAs  
**Goal:** Profit from price movements  
**Example:** A trader buys crude oil futures expecting prices to rise due to geopolitical tension.

### 3. Market Makers

**Who:** Banks, trading firms  
**Goal:** Provide liquidity by quoting bid/ask prices  
**Example:** Goldman Sachs quotes $78.40 bid / $78.45 ask for WTI crude.

### 4. Arbitrageurs

**Who:** Sophisticated traders exploiting price differences  
**Goal:** Risk-free profit from mispricings  
**Example:** Buy Brent at $82, sell WTI at $78 if spread narrows (Brent-WTI spread trade).

---

## 📈 Key Trading Concepts

### 1. Settlement Prices

**Definition:**  
The **official closing price** determined by the exchange at end of trading day.

**How It's Determined:**
- **Volume-weighted average** of trades during final settlement period (usually last few minutes)
- **Settlement committee** may adjust if insufficient liquidity
- **Published after market close** (e.g., 2:30 PM CT for NYMEX)

**Why Settlement Prices Matter:**
- **Mark-to-market:** All open positions valued at settlement price
- **Margin calls:** If losses exceed margin, traders must deposit more funds
- **Cash settlement:** Financial contracts settle in cash based on final settlement price
- **Regulatory reporting:** Official prices for compliance

**Example:**  
You hold 100 WTI crude futures at $75/barrel. Today's settlement is $78.45.  
Your profit today: (78.45 - 75.00) × 1,000 barrels × 100 contracts = **$345,000**

---

### 2. Futures Contracts

**Definition:**  
A **standardized agreement** to buy/sell a commodity at a predetermined price on a future date.

**Contract Specifications:**

| Element | Example (WTI Crude) |
|---------|---------------------|
| **Underlying** | Light sweet crude oil |
| **Contract Size** | 1,000 barrels |
| **Price Quote** | USD per barrel |
| **Tick Size** | $0.01 = $10 per contract |
| **Delivery Month** | Every month |
| **Last Trading Day** | 3rd business day before 25th calendar day |
| **Delivery Location** | Cushing, Oklahoma |

**Key Features:**
- **Standardized** - Same terms for all market participants
- **Exchange-traded** - Centralized, transparent pricing
- **Margin-based** - Only deposit a fraction of contract value (leverage)
- **Daily settlement** - Gains/losses realized daily
- **Can close before expiry** - Most contracts closed, not delivered

---

### 3. Forward Curve

**Definition:**  
A chart showing futures prices for different delivery months.

**Example (Natural Gas Forward Curve):**

| Contract Month | Settlement Price | Reason |
|----------------|------------------|--------|
| Apr-24 | $2.10/MMBtu | Low demand (shoulder season) |
| Jul-24 | $2.45/MMBtu | Summer cooling demand |
| Jan-25 | $3.80/MMBtu | Winter heating demand |
| Apr-25 | $2.20/MMBtu | Return to low demand |

**Curve Shapes:**

1. **Contango** - Later months more expensive (normal for storable commodities)
   - Reflects storage costs and interest rates
   - Example: Apr $2.10, Jan $3.80

2. **Backwardation** - Near months more expensive (shortage/high demand)
   - Immediate demand exceeds supply
   - Example: Crude during supply disruptions

**Uses:**
- **Hedging strategy** - Which months to hedge?
- **Storage trades** - Buy physical, sell futures if contango is profitable
- **Valuation** - Price long-term supply contracts

---

### 4. Spreads

**Definition:**  
The **price difference** between two related contracts.

**Types:**

#### A. Calendar Spread
Price difference between two delivery months.

**Example:** WTI Jun-24 $78.50 vs. Dec-24 $75.20 = **+$3.30 contango**

**Uses:**
- Storage profitability (buy spot, sell future, store oil)
- Seasonal patterns

#### B. Crack Spread
Refining margin (refined products - crude oil).

**Example:**  
- RBOB Gasoline: $2.50/gallon × 42 gallons = $105/barrel
- WTI Crude: $78/barrel
- **Crack Spread: $105 - $78 = $27/barrel** (refining profit)

**Uses:**
- Refinery profitability
- Hedging for refiners

#### C. Location Spread
Price difference between two delivery locations.

**Example:** Brent $82/barrel - WTI $78/barrel = **+$4 Brent premium**

**Reasons for spread:**
- Transportation costs
- Quality differences (Brent vs. WTI)
- Supply/demand imbalances

---

### 5. Margin and Mark-to-Market

**Initial Margin:**  
Deposit required to open a futures position (e.g., $6,000 per WTI contract).

**Maintenance Margin:**  
Minimum balance to keep position open (e.g., $5,500).

**Mark-to-Market:**  
Daily settlement of gains/losses.

**Example:**

| Day | Settlement | Position | Daily P&L | Margin Account |
|-----|------------|----------|-----------|----------------|
| Mon | $78.00 | Long 10 | - | $60,000 (initial) |
| Tue | $78.45 | Long 10 | +$4,500 | $64,500 |
| Wed | $77.80 | Long 10 | -$6,500 | $58,000 |

On Wednesday, margin is below maintenance ($55,000). **Margin call issued** - deposit $7,000 to restore to $65,000.

---

### 6. Volume and Open Interest

**Volume:**  
Number of contracts **traded** during a day.

**Open Interest:**  
Number of contracts **still open** (not yet closed or delivered).

**Interpretation:**

| Volume | Open Interest | Meaning |
|--------|---------------|---------|
| High | Increasing | Strong new interest, trending market |
| High | Decreasing | Position unwinding, potential trend reversal |
| Low | Increasing | Quiet accumulation |
| Low | Decreasing | Lack of interest, illiquid market |

**Example:**
- WTI Jun-24: Volume = 245,000 contracts, Open Interest = 1,234,567
- High liquidity, active trading

---

## 🏢 Major Exchanges

### 1. CME Group (Chicago Mercantile Exchange)

**Key Markets:**
- NYMEX (crude oil, natural gas, refined products)
- COMEX (metals)

**Trading Hours:** Nearly 24 hours (electronic via CME Globex)

**Settlement:** 2:30 PM CT

**Website:** https://www.cmegroup.com/

---

### 2. ICE (Intercontinental Exchange)

**Key Markets:**
- Brent crude oil
- European natural gas (TTF, NBP)
- Power (US and Europe)

**Trading Hours:** 24 hours (electronic)

**Settlement:** Varies by product

**Website:** https://www.theice.com/

---

### 3. Other Exchanges

- **DME (Dubai Mercantile Exchange)** - Middle East crude
- **TOCOM (Tokyo Commodity Exchange)** - Asian energy
- **EEX (European Energy Exchange)** - European power, gas

---

## 📅 Trading Calendar

### Contract Months

**Notation:**
- **Feb-24** = February 2024 delivery
- **F24** = February 2024 (exchange notation)
- **CLF24** = WTI Crude, February 2024

**Expiry Cycle:**
- Most energy products: **Monthly contracts**
- Some power products: **Daily, weekly, monthly, quarterly, annual**

### Last Trading Day

**WTI Crude:** 3rd business day before 25th calendar day of month prior to delivery month

**Example:** For May 2024 contract (CLK24):
- Delivery month: May 2024
- Last trading: April 19, 2024 (3 business days before April 25)

### Roll Period

**What It Is:** Transitioning from expiring "front month" to next month.

**Example (Natural Gas):**
- Current front month: Apr-24 (expires March 27)
- New front month: May-24
- Roll period: March 20-27 (traders close Apr, open May)

**Market Impact:** High volume, potential price distortions

---

## 💹 Price Drivers

### 1. Supply Factors

**Crude Oil:**
- OPEC+ production quotas
- US shale output
- Geopolitical disruptions (wars, sanctions)
- Maintenance/outages

**Natural Gas:**
- Production growth (associated gas from oil drilling)
- Pipeline capacity
- LNG export capacity

**Power:**
- Generation capacity (power plants online)
- Renewable output (wind, solar)
- Fuel availability (gas, coal, hydro)

---

### 2. Demand Factors

**Crude Oil:**
- Economic growth (more driving, flying)
- Refinery runs (demand for feedstock)
- Strategic petroleum reserve purchases

**Natural Gas:**
- Weather (heating degree days, cooling degree days)
- Power generation demand
- Industrial demand
- LNG exports

**Power:**
- Weather (extreme heat/cold)
- Time of day (peak vs. off-peak)
- Day of week (weekday vs. weekend)

---

### 3. Storage

**Crude Oil:**
- Cushing, Oklahoma inventories (WTI)
- US commercial inventories (EIA weekly report)
- Global floating storage (tankers at sea)

**Natural Gas:**
- US underground storage (EIA weekly report every Thursday)
- Storage capacity: ~4,000 Bcf (billion cubic feet)
- Injection season: Apr-Oct, Withdrawal season: Nov-Mar

**Interpretation:**
- **Storage above 5-year average** → Bearish (oversupply)
- **Storage below 5-year average** → Bullish (shortage)

---

### 4. Macroeconomic Factors

- **US Dollar Strength** - Stronger dollar → lower commodity prices (inverse correlation)
- **Interest Rates** - Higher rates → higher storage costs → contango
- **Economic Growth** - GDP growth → higher energy demand
- **Inflation** - Energy is inflation hedge

---

## 🎓 Advanced Concepts

### 1. Crack Spreads (Refining)

**3-2-1 Crack Spread:**  
Refining 3 barrels crude → 2 barrels gasoline + 1 barrel heating oil.

**Calculation:**
```
(2 × RBOB + 1 × HO) / 3 - WTI Crude
```

**Example:**
- RBOB: $2.50/gal × 42 gal = $105/bbl
- HO: $2.40/gal × 42 gal = $100.80/bbl
- WTI: $78/bbl

**Crack Spread:** (2×105 + 1×100.80)/3 - 78 = $25.27/barrel

**Interpretation:** Refiners profit $25.27 per barrel refined.

---

### 2. Spark Spread (Power Generation)

**Definition:**  
Profit from burning natural gas to generate electricity.

**Calculation:**
```
Power Price ($/MWh) - (Gas Price × Heat Rate)
```

**Example:**
- Power: $45/MWh
- Natural Gas: $2.50/MMBtu
- Heat Rate: 7.5 MMBtu/MWh (efficiency)

**Spark Spread:** 45 - (2.50 × 7.5) = $26.25/MWh

**Interpretation:** Power plant profits $26.25 per megawatt-hour generated.

---

### 3. Basis Trading

**Definition:**  
Price difference between physical location and futures price.

**Example:**
- WTI Cushing futures: $78/barrel
- West Texas Midland physical: $77.50/barrel
- **Basis:** -$0.50/barrel (discount to Cushing)

**Reasons for Basis:**
- Transportation costs
- Quality differences
- Local supply/demand

---

### 4. Options on Futures

**Definition:**  
Right (not obligation) to buy (call) or sell (put) a futures contract at a specific price (strike).

**Example:**
- Buy WTI $80 Call, expiry Jun-24, premium $2/barrel
- If WTI settles at $85, exercise option → profit $3/barrel ($5 - $2 premium)
- If WTI settles at $75, let option expire → loss $2/barrel (premium)

**Uses:**
- Hedging with limited downside (pay premium)
- Speculation with defined risk

---

## 📐 Risk Management

### Value at Risk (VaR)

**Definition:**  
Maximum expected loss over a time period at a given confidence level.

**Example:**  
"Daily VaR is $500,000 at 95% confidence" means:
- 95% of days, losses will be less than $500,000
- 5% of days, losses could exceed $500,000

**Calculation (Historical VaR):**
1. Get historical daily returns (e.g., last 1 year)
2. Sort returns from worst to best
3. Find 5th percentile (95% confidence)
4. Apply to current portfolio value

---

### Stress Testing

**Definition:**  
Simulate portfolio performance under extreme scenarios.

**Example Scenarios:**
- Crude oil drops 30% (recession)
- Natural gas spikes 200% (supply disruption)
- Power prices negative (renewable oversupply)

---

### Hedging Strategies

**Example: Airline Jet Fuel Hedge**

**Problem:** Airline needs 1 million barrels jet fuel in 2024. Current price $85/barrel. Worried about price increase.

**Solution:** Buy 1,000 crude oil futures (proxy for jet fuel).
- If crude rises to $95, futures profit $10/barrel = $10 million gain
- Offset by $10 million higher jet fuel cost
- **Net result:** Locked in ~$85/barrel effective price

---

## 📊 Data Fields Explained

### Key Fields in Settlement Price Data

| Field | Description | Example | Use |
|-------|-------------|---------|-----|
| **instrument_id** | Unique contract identifier | CL.FUT | Identify specific product |
| **instrument_name** | Human-readable name | WTI Crude Oil | Reporting |
| **trade_date** | Business date of trading | 2024-03-15 | Time series analysis |
| **settlement_price** | Official closing price | 78.45 | Mark-to-market |
| **contract_month** | Delivery month | 2024-05 | Forward curve, rolls |
| **volume** | Contracts traded that day | 245,000 | Liquidity indicator |
| **open_interest** | Contracts still open | 1,234,567 | Market depth |
| **daily_change** | Price change vs. previous day | +0.75 | Momentum |
| **percent_change** | % change vs. previous day | +0.96% | Volatility |

---

## 🎯 Practical Examples

### Example 1: Portfolio Valuation

**Scenario:** You hold:
- 100 WTI crude contracts (long), bought at $75/barrel
- 50 natural gas contracts (short), sold at $3.00/MMBtu

**Today's Settlements:**
- WTI: $78.45/barrel
- Natural Gas: $2.45/MMBtu

**Valuation:**
- WTI P&L: (78.45 - 75.00) × 1,000 bbls × 100 = **+$345,000**
- NG P&L: (3.00 - 2.45) × 10,000 MMBtu × 50 = **+$275,000**
- **Total P&L: +$620,000**

---

### Example 2: Refinery Optimization

**Scenario:** Refinery can process 100,000 barrels/day crude. Decides daily whether to run or shut down based on crack spread.

**Today's Prices:**
- WTI Crude: $78/barrel
- RBOB Gasoline: $2.50/gallon = $105/barrel
- Heating Oil: $2.40/gallon = $100.80/barrel

**Crack Spread:** (2×105 + 1×100.80)/3 - 78 = **$25.27/barrel**

**Operating Cost:** $15/barrel

**Decision:** Run refinery (profit $10.27/barrel × 100,000 = **$1,027,000/day**)

---

### Example 3: Storage Trade

**Scenario:** Natural gas storage facility (capacity 5 Bcf, cost $0.05/MMBtu/month).

**Prices:**
- Apr-24 spot: $2.10/MMBtu
- Jan-25 futures: $3.80/MMBtu
- Contango: **$1.70/MMBtu**

**Storage Economics:**
- Buy Apr at $2.10, sell Jan futures at $3.80
- Storage cost: $0.05/MMBtu × 9 months = $0.45/MMBtu
- **Profit: $3.80 - $2.10 - $0.45 = $1.25/MMBtu**
- **Total: $1.25 × 5 Bcf = $6.25 million profit**

---

## 📚 Additional Learning Resources

### Industry Reports

- **EIA Weekly Petroleum Status Report** - US oil inventories
- **EIA Natural Gas Storage Report** - Every Thursday 10:30 AM ET
- **IEA Monthly Oil Market Report** - Global supply/demand
- **OPEC Monthly Report** - Production, demand forecasts

### Market Data Providers

- **Bloomberg** - Comprehensive real-time data
- **Refinitiv (Reuters)** - News and analytics
- **Platts** - Physical market assessments
- **Argus** - Independent price reporting

### Educational Websites

- **CME Institute** - Free courses on futures trading
- **ICE Academy** - Energy market fundamentals
- **FERC** - US power market regulations
- **EIA** - US energy data and analysis

---

## 🎓 Glossary

**Backwardation** - Near-term contracts more expensive than future contracts  
**Basis** - Price difference between physical and futures  
**Bcf** - Billion cubic feet (natural gas volume)  
**Contango** - Future contracts more expensive than near-term  
**Crack Spread** - Refining margin (products - crude)  
**Heat Rate** - Efficiency of power plant (MMBtu/MWh)  
**Henry Hub** - Louisiana natural gas pricing point  
**MMBtu** - Million British thermal units  
**Open Interest** - Number of outstanding futures contracts  
**Prompt Month** - Nearest expiring contract (front month)  
**Settlement Price** - Official daily closing price  
**Spark Spread** - Power generation margin  
**Strip** - Series of consecutive futures contracts  
**Tick** - Minimum price movement ($0.01 for crude)  
**VaR** - Value at Risk (risk metric)

---

## 💡 Key Takeaways

1. **Settlement prices are official** - Used for marking portfolios, margin calls, cash settlement
2. **Forward curve shows time value** - Different delivery months have different prices
3. **Storage drives contango** - Costs of holding commodities
4. **Spreads reveal relationships** - Refining margins, location differences
5. **Volume + Open Interest = Liquidity** - Essential for large trades
6. **Weather drives gas/power** - Seasonal patterns
7. **Geopolitics drives oil** - Supply disruptions
8. **Data quality matters** - Bad data = bad decisions, huge financial impact

---

**This knowledge helps you understand WHY the data you're processing is so critical to traders and risk managers!**
