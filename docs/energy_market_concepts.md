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

### 4. Power/Electricity Markets

**What It Is:**  
Electricity traded for delivery at specific locations (nodes) and times. Unlike other commodities, electricity cannot be economically stored at scale, requiring real-time balancing of supply and demand.

#### 🌍 Global Power Markets Overview

**Unique Characteristics:**
- **No Storage** - Must balance supply/demand every second
- **Instantaneous Delivery** - Speed of light transmission
- **Locational Pricing** - Different prices at different grid locations
- **Time Dependency** - Hour-by-hour, even minute-by-minute pricing
- **Extreme Volatility** - Prices can spike 100x to 1000x during shortages
- **Physical Constraints** - Transmission capacity limits

---

## ⚡ ICE (Intercontinental Exchange) European Power Markets

### Overview

**ICE** is the **leading exchange** for European wholesale electricity trading, covering the largest and most liquid power markets in Europe.

**Key European Power Markets Traded on ICE:**

| Country/Region | Market | Hub/Zone | Currency | Settlement |
|----------------|--------|----------|----------|------------|
| **Germany** | German Power | EPEX/EEX | EUR/MWh | Day-Ahead, Futures |
| **UK** | UK Power | N2EX | GBP/MWh | Day-Ahead, Futures |
| **France** | French Power | EPEX | EUR/MWh | Day-Ahead, Futures |
| **Netherlands** | Dutch Power | APX | EUR/MWh | Day-Ahead, Futures |
| **Belgium** | Belgian Power | Belpex | EUR/MWh | Day-Ahead, Futures |
| **Nordic** | Nordic Power (Nord Pool) | System Price | EUR/MWh | Day-Ahead, Futures |
| **Italy** | Italian Power | GME | EUR/MWh | Day-Ahead, Futures |
| **Spain** | Spanish Power | OMIE | EUR/MWh | Day-Ahead, Futures |

---

### European Power Market Structure

#### 1. Day-Ahead Market (Spot Market)

**What It Is:**  
Auction-based market where power for **next day delivery** is traded **hour-by-hour**.

**How It Works:**

```
Timeline:
Day D:  12:00 PM → Gate Closure (auction closes)
        12:30 PM → Market Clearing (prices published)
        3:00 PM  → Final schedules published
Day D+1: 00:00 AM → Physical delivery begins
```

**Example - German Day-Ahead (EPEX SPOT):**

| Hour | Demand (GW) | Supply (GW) | Clearing Price (EUR/MWh) |
|------|-------------|-------------|--------------------------|
| 00:00-01:00 | 45 | 52 | €35.50 (low demand) |
| 12:00-13:00 | 68 | 70 | €65.80 (peak demand) |
| 18:00-19:00 | 72 | 71 | €85.40 (evening peak) |
| 02:00-03:00 | 42 | 55 | €25.20 (night low) |

**Key Concepts:**

- **System Marginal Price (SMP)** - Price of most expensive generator needed to meet demand
- **Price Coupling of Regions (PCR)** - Integrated European day-ahead market
- **Market Coupling** - Automated flow of power between countries based on price differences

**Market Coupling Example:**

```
Before Coupling:
Germany: €60/MWh (high wind, excess supply)
France:  €80/MWh (low nuclear, tight supply)

After Coupling via Interconnector:
Germany exports to France
Germany: €68/MWh (price rises due to export)
France:  €72/MWh (price falls due to import)
Convergence toward equilibrium!
```

---

#### 2. Intraday Market

**What It Is:**  
**Continuous trading** market for power delivery on **same day**, allowing adjustments after day-ahead auction.

**Trading Timeline:**

```
Day D:   15:00 → Intraday market opens (for next day)
Day D+1: 00:00 → Physical delivery starts
         05:00 → Hour 6-7 delivery (trading continues until 5 minutes before)
         23:55 → Last trades for final hour (23:00-24:00)
```

**Why Intraday Matters:**

1. **Renewable Forecasting** - Adjust for actual wind/solar vs. forecast
2. **Plant Outages** - Cover unexpected generation failures
3. **Demand Variations** - Respond to temperature changes
4. **Balancing** - Fine-tune positions before real-time

**Example - Wind Forecast Error:**

```
Day-Ahead Forecast: 10 GW wind generation
Actual (Intraday):  6 GW wind generation (low wind speeds)

Action: Power company buys 4 GW in intraday market
Price Impact: Intraday price spikes from €50 to €75/MWh
```

---

#### 3. Futures Market (Forward Market)

**What It Is:**  
Contracts for **future power delivery** (weeks, months, quarters, years ahead).

**ICE European Power Futures:**

| Product | Delivery Period | Use Case |
|---------|-----------------|----------|
| **Baseload** | 24 hours/day, entire period | Constant load hedging |
| **Peak Load** | 8 AM - 8 PM weekdays only | Industrial/commercial |
| **Off-Peak** | Nights + weekends | Low-value periods |
| **Monthly** | Entire calendar month | Short-term hedging |
| **Quarterly** | Q1, Q2, Q3, Q4 | Seasonal hedging |
| **Annual** | Calendar year | Long-term contracts |

**Example - German Power Annual Futures:**

| Contract | Delivery | Trading Price (EUR/MWh) | Volume |
|----------|----------|-------------------------|--------|
| Cal-24 | Jan-Dec 2024 | €95.50 | 125,000 MWh |
| Cal-25 | Jan-Dec 2025 | €88.20 | 98,000 MWh |
| Cal-26 | Jan-Dec 2026 | €82.50 | 45,000 MWh |

**Baseload vs. Peak Example:**

```
German Power Cal-24:
Baseload: €95.50/MWh (24h/day × 365 days = 8,760 hours)
Peak:     €115.30/MWh (12h/day × 261 weekdays = 3,132 hours)

Peak Premium: €19.80/MWh (20.7% higher)
Reason: Peak hours have higher demand, lower renewable output
```

---

### European Power Market Participants

#### 1. Generators (Power Producers)

**Types:**
- **Utilities** - E.ON, RWE, EDF, Vattenfall, Enel
- **Renewable Operators** - Wind farms, solar parks
- **Gas-Fired Plants** - Flexible peaking plants
- **Nuclear Operators** - Baseload generation

**Hedging Strategy:**
```
Wind Farm:
- Produces 200 GWh/year (uncertain timing)
- Sells 150 GWh as baseload futures (secure revenue)
- Sells 50 GWh in day-ahead/intraday (optimize actual production)
- Hedge ratio: 75% to lock in revenue
```

#### 2. Suppliers (Retailers)

**Who:** Companies selling electricity to end-users (homes, businesses)

**Example:** German Retail Supplier

```
Customer Load: 500 GWh/year
Procurement Strategy:
- 200 GWh: Long-term annual futures (price certainty)
- 200 GWh: Quarterly futures (seasonal optimization)
- 80 GWh: Monthly futures (flexibility)
- 20 GWh: Day-ahead market (fine-tuning)
```

#### 3. Traders & Speculators

**Strategies:**
- **Spread Trading** - Exploit price differences between countries
- **Calendar Spreads** - Summer vs. Winter pricing
- **Volatility Trading** - Options on power futures
- **Weather Trading** - Profit from temperature forecast changes

#### 4. Industrial Consumers

**Large Users:** Aluminum smelters, steel mills, data centers, chemical plants

**Hedging Example:**
```
Aluminum Smelter:
Annual Consumption: 1,200 GWh
Electricity Cost: 40% of production cost

Hedge: Buy 1,000 GWh Cal-24 futures at €90/MWh
Result: Lock in predictable costs for budgeting
```

---

### Power Market Pricing Dynamics

#### Merit Order Dispatch

**Concept:** Generators dispatched in order of **marginal cost** (cheapest first).

**Typical European Merit Order:**

| Technology | Marginal Cost | Capacity Factor | Dispatch Order |
|------------|---------------|-----------------|----------------|
| Solar | €0/MWh | 11% (daytime only) | 1st (when sunny) |
| Wind | €0/MWh | 25% (variable) | 1st (when windy) |
| Nuclear | €10/MWh | 85% (baseload) | 2nd |
| Hydro (run-of-river) | €5/MWh | 40% | 2nd |
| Lignite (coal) | €25/MWh | 60% | 3rd |
| Hard Coal | €40/MWh | 40% | 4th |
| Gas CCGT (efficient) | €55/MWh | 50% | 5th |
| Gas Open Cycle | €90/MWh | 10% (peaking) | 6th |
| Oil | €120/MWh | 5% (emergency) | 7th |

**Price Setting Example:**

```
Hour 14:00 (High Demand - 70 GW):
Solar:     15 GW (€0)
Wind:      12 GW (€0)
Nuclear:   10 GW (€10)
Hydro:     5 GW (€5)
Coal:      18 GW (€25-€40)
Gas CCGT:  10 GW (€55) ← Marginal plant sets price

Market Clearing Price: €55/MWh
(All generators receive €55, even if their cost is €0!)

Hour 03:00 (Low Demand - 45 GW):
Wind:      12 GW (€0) ← Marginal plant
Nuclear:   10 GW (€10)
Hydro:     8 GW (€5)
Coal:      15 GW (€25)

Market Clearing Price: €25/MWh
(Lower demand = cheaper marginal plant)
```

---

### Renewable Integration Challenges

#### 1. Negative Prices

**When It Happens:**  
High renewable output + low demand = oversupply

**Example - German Sunday Morning:**

```
Time: 11:00 AM, sunny Sunday in May
Solar Output: 35 GW (record high)
Wind Output: 20 GW (strong winds)
Total Renewable: 55 GW
Demand: Only 40 GW (low Sunday demand)

Oversupply: 15 GW
Nuclear/Coal: Cannot shut down quickly
Solution: Pay consumers to take power!

Price: -€50/MWh (NEGATIVE!)
```

**Real Example - Germany April 2020:**
- Negative prices for 128 hours during month
- Lowest: -€83.94/MWh
- Reason: COVID lockdowns (low demand) + high wind/solar

**Who Benefits:**
- Large industrial consumers (paid to consume!)
- Battery storage operators (charge batteries, get paid)
- Pump storage (pump water uphill, store energy)

#### 2. Curtailment

**What It Is:**  
Paying renewable generators to **shut down** when grid can't handle output.

**Example:**
```
Wind Farm Curtailment Order:
"Reduce output from 100 MW to 50 MW for 3 hours"

Compensation:
Lost Generation: 150 MWh
Market Price: €60/MWh
Payment: €9,000 (to compensate for lost revenue)
```

#### 3. Capacity Markets

**Problem:** Renewables don't provide reliability (no sun/wind at night/calm days)

**Solution:** Pay conventional plants to **stay available** even if not running.

**UK Capacity Market Example:**

```
Gas Plant (500 MW):
Capacity Payment: £45,000/MW/year
Total Revenue: £22.5 million/year (just for being available!)

Plus: Energy payments when actually running
Result: Plant stays open for backup, ensuring security of supply
```

---

### Cross-Border Trading (Market Coupling)

#### Interconnector Capacity

**Key European Interconnectors:**

| Connection | Capacity (MW) | Annual Flow | Main Flow Direction |
|------------|---------------|-------------|---------------------|
| France-UK | 2,000 | 15 TWh | France → UK (nuclear) |
| Germany-France | 3,000 | 20 TWh | Germany → France (renewables) |
| Norway-Germany | 1,400 | 10 TWh | Norway → Germany (hydro) |
| Belgium-UK | 1,000 | 7 TWh | Bidirectional |
| Spain-France | 2,800 | 8 TWh | Spain → France (wind/solar) |

**Price Convergence Example:**

```
Before Market Coupling:
UK Price: £120/MWh (low wind, tight supply)
France Price: €70/MWh (high nuclear output)

Interconnector Capacity: 2,000 MW available
Price Differential: £50/MWh (€57/MWh at £1=€1.15)

Action: Maximize France → UK flow (2,000 MW)

After Coupling:
UK Price: £95/MWh (import reduces scarcity)
France Price: €85/MWh (export absorbs surplus)
Convergence achieved!

Trader Profit: (€108 - €85) × 2,000 MW × 1 hour = €46,000
```

---

### Power Market Data Fields (Settlement Prices)

**Typical ICE European Power Settlement Data:**

| Field | Example | Description |
|-------|---------|-------------|
| `instrument_id` | DE.PWR.BASE.M01 | Germany Power Baseload Month 1 |
| `market` | German Power | Country/region |
| `product_type` | Baseload / Peak | Load profile |
| `delivery_start` | 2024-05-01 00:00 | Delivery begins |
| `delivery_end` | 2024-05-31 23:59 | Delivery ends |
| `settlement_price` | 95.50 | EUR/MWh |
| `volume` | 12,450 | MWh traded |
| `open_interest` | 245,678 | MWh open positions |
| `price_type` | Day-Ahead / Futures | Market type |

**Common Instrument Naming:**

```
DE.PWR.BASE.CAL24  = German Power Baseload Calendar Year 2024
UK.PWR.PEAK.Q2-24  = UK Power Peak Quarter 2 2024
FR.PWR.BASE.M05-24 = French Power Baseload May 2024
NL.PWR.OFFPK.W22   = Dutch Power Off-Peak Week 22
```

---

### Real-World Power Trading Example

#### Scenario: German Utility Hedging Strategy

**Company:** Regional German power supplier  
**Annual Sales:** 2,000 GWh to residential/commercial customers  
**Date:** January 2024  
**Goal:** Hedge power purchases for 2024

**Market Analysis:**

```
Current Prices (January 2024):
Cal-24 Baseload: €95.50/MWh
Q2-24 Baseload: €72.30/MWh (low demand)
Q4-24 Baseload: €110.20/MWh (high demand)
Peak Premium: +€18/MWh vs. baseload
```

**Hedging Strategy:**

| Product | Volume (GWh) | Price (EUR/MWh) | Total Cost (€M) |
|---------|--------------|-----------------|-----------------|
| Cal-24 Baseload | 1,000 | 95.50 | 95.50 |
| Q2-24 Baseload | 200 | 72.30 | 14.46 |
| Q4-24 Peak | 400 | 128.20 | 51.28 |
| Day-Ahead (buffer) | 400 | Variable | TBD |
| **Total** | **2,000** | **Avg €94.37** | **€161.24M** |

**Risk Management:**

- **80% Hedged** - Price certainty for budgeting
- **20% Spot Exposure** - Flexibility for optimization
- **Quarterly Adjustments** - Update hedges as forecasts change

**Outcome (Hypothetical):**

```
Actual Average Day-Ahead 2024: €102.50/MWh
Hedged Cost: €94.37/MWh
Savings: €8.13/MWh × 1,600 GWh = €13 million saved!
```

---

### Advanced Power Market Concepts

#### 1. Locational Marginal Pricing (LMP)

**Concept:** Different prices at different locations due to transmission constraints.

**Example - Grid Congestion:**

```
Scenario: North Germany has excess wind, South Germany has high demand

North (Wind Farm Zone):
Generation: 15 GW
Demand: 8 GW
Price: €30/MWh (surplus)

South (Industrial Zone):
Generation: 5 GW
Demand: 12 GW
Price: €80/MWh (deficit)

Transmission Line Capacity: Only 5 GW
Bottleneck: Cannot send all cheap northern power south

Result: Price differential of €50/MWh
Transmission Congestion Rent: €50 × 5 GW × 1h = €250,000/hour
```

#### 2. Ancillary Services Markets

**Frequency Regulation:**

```
Grid Frequency: Must stay at 50.00 Hz ± 0.2 Hz
Pay for services:
- Primary Reserve: Activate in 30 seconds (€XX/MW/h)
- Secondary Reserve: Activate in 5 minutes (€XX/MW/h)
- Tertiary Reserve: Activate in 15 minutes (€XX/MW/h)
```

**Example Payment:**

```
Battery Storage Facility (50 MW):
Primary Reserve Capacity Payment: €25/MW/hour
Revenue: 50 MW × €25 × 8,760 hours = €10.95M/year

Plus: Energy payments when activated
Total Revenue: €15-20M/year (just for being available!)
```

#### 3. Balancing Markets

**Purpose:** Real-time balancing of actual vs. scheduled generation/consumption.

**How It Works:**

```
Hour 14:00 Scheduled:
Generation: 60 GW
Demand: 60 GW
Balanced ✓

Hour 14:15 Actual:
Generation: 58 GW (wind dropped unexpectedly)
Demand: 60 GW
Imbalance: -2 GW (shortage)

Grid Operator Action:
Activate reserve generators (+2 GW)
Balancing Price: €150/MWh (3x normal price!)

Imbalance Penalties:
Party responsible for shortage pays €150 × 2,000 MW × 0.25h = €75,000
```

---

### Key European Power Market Regulations

#### 1. Emissions Trading System (EU ETS)

**Carbon Pricing Impact on Power:**

```
Coal Plant (40% efficiency):
Carbon Emissions: 0.8 tCO2/MWh
Carbon Price: €80/tCO2
Carbon Cost: €64/MWh

Gas Plant (60% efficiency):
Carbon Emissions: 0.35 tCO2/MWh
Carbon Price: €80/tCO2
Carbon Cost: €28/MWh

Result: Gas becomes more competitive vs. coal
Merit order shifts: Gas displaces coal
Power prices rise by carbon cost
```

#### 2. Renewable Energy Targets

**EU Renewable Directive:**
- 2030 Target: 42.5% renewable electricity
- 2050 Goal: Climate neutrality (100% clean energy)

**Impact on Markets:**
- More price volatility (weather-dependent generation)
- Increased negative price events
- Need for flexibility (batteries, demand response)
- Higher capacity market payments

---

### ICE Power Market Trading Hours

| Market | Trading Hours (CET) | Auction Time |
|--------|---------------------|--------------|
| German Day-Ahead | 00:00 - 12:00 | 12:00 (results 12:30) |
| UK Day-Ahead | 00:00 - 11:00 | 11:00 (results 11:30) |
| French Day-Ahead | 00:00 - 12:00 | 12:00 |
| Intraday (continuous) | 15:00 D-1 to 5 min before delivery | N/A (continuous) |
| Futures | 08:00 - 18:00 | N/A (continuous) |

---

## 🌐 Other Major Power Markets (Quick Reference)

### US Power Markets

**Regional Transmission Organizations (RTOs):**

| RTO/ISO | Region | Pricing | Key Features |
|---------|--------|---------|--------------|
| **PJM** | Mid-Atlantic, Midwest | LMP (Locational Marginal Pricing) | Largest RTO, 65 million people |
| **ERCOT** | Texas | Nodal LMP | Isolated grid, extreme volatility |
| **CAISO** | California | LMP | High renewable integration |
| **NYISO** | New York | LMP | Urban constraints |
| **ISO-NE** | New England | LMP | Winter peak challenges |

**ERCOT Notable Event:**

```
Texas Winter Storm (February 2021):
Normal Price: $50/MWh
Crisis Price: $9,000/MWh (price cap!)
Duration: 4 days
Total Cost: $50 billion
Cause: Gas supply freeze + power plant outages
```

### Asian Power Markets

**Singapore:**
- Uniform Singapore Energy Price (USEP)
- Half-hourly pricing
- Gas-fired generation dominant

**Australia (NEM - National Electricity Market):**
- 5-minute settlement
- Highly volatile (renewable integration)
- Price cap: AUD $15,500/MWh

**Japan:**
- JEPX (Japan Electric Power Exchange)
- Day-ahead and intraday
- Post-Fukushima nuclear phase-out

---

### Why Power Market Data Matters

**For This ETL System:**

1. **Portfolio Valuation** - Mark-to-market power derivatives
2. **Risk Management** - VaR calculations on volatile power positions
3. **Hedging Decisions** - When to lock in prices
4. **Arbitrage** - Cross-border, calendar spreads
5. **Regulatory Reporting** - Compliance with REMIT (EU market abuse)
6. **Forecasting** - Predict forward curve movements

**Data Quality Critical:**

```
Error Example:
Incorrect Settlement: €95/MWh recorded as €9.50/MWh
Position: 10,000 MWh
Valuation Error: €855,000!

Impact: Wrong P&L, wrong margin calls, compliance issues
```

---

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

### General Trading Terms
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

### Power Market Specific Terms
**Ancillary Services** - Grid support services (frequency regulation, reserves)  
**Baseload** - Constant power delivery 24 hours/day  
**Balancing Market** - Real-time market for grid balancing  
**Capacity Market** - Payment for being available (not generating)  
**Curtailment** - Paying generators to reduce output  
**Day-Ahead Market** - Auction for next-day power delivery  
**EPEX** - European Power Exchange (spot markets)  
**EU ETS** - European Union Emissions Trading System (carbon pricing)  
**Intraday Market** - Continuous trading for same-day delivery  
**Interconnector** - High-voltage cable connecting country grids  
**LMP** - Locational Marginal Pricing (different prices at different nodes)  
**Market Coupling** - Integrated European power markets  
**Merit Order** - Dispatch order from cheapest to most expensive generation  
**MWh** - Megawatt-hour (1,000 kWh)  
**Negative Prices** - Paying consumers to take excess power  
**Off-Peak** - Nights, weekends (low demand periods)  
**Peak Load** - High demand hours (typically 8 AM - 8 PM weekdays)  
**PCR** - Price Coupling of Regions (EU market integration)  
**REMIT** - Regulation on Energy Market Integrity and Transparency (EU)  
**RTO/ISO** - Regional Transmission Organization / Independent System Operator  
**System Marginal Price (SMP)** - Price of most expensive generator running  
**Transmission Constraint** - Physical limit on power flow through lines  
**TWh** - Terawatt-hour (1 billion kWh)

### ICE-Specific Terms
**ICE** - Intercontinental Exchange (major energy exchange)  
**N2EX** - ICE's UK power exchange  
**Nord Pool** - Nordic and Baltic power exchange (part of ICE group)

---

## 💡 Key Takeaways

1. **Settlement prices are official** - Used for marking portfolios, margin calls, cash settlement
2. **Forward curve shows time value** - Different delivery months have different prices
3. **Storage drives contango** - Costs of holding commodities (except power - cannot store!)
4. **Spreads reveal relationships** - Refining margins, location differences, calendar patterns
5. **Volume + Open Interest = Liquidity** - Essential for large trades
6. **Weather drives gas/power** - Seasonal patterns, temperature extremes
7. **Geopolitics drives oil** - Supply disruptions, OPEC decisions
8. **Renewables drive power volatility** - Wind/solar variability creates price swings
9. **Power cannot be stored** - Real-time balancing creates unique market dynamics
10. **Data quality matters** - Bad data = bad decisions, huge financial impact

### Power Market Specific Takeaways

11. **Merit order determines prices** - Marginal cost of last generator sets market price
12. **Renewable integration is complex** - Creates negative prices, curtailment, capacity markets
13. **Location matters for power** - Transmission constraints create different prices at different nodes
14. **Time matters for power** - Hour-by-hour pricing, peak vs. off-peak premiums
15. **Cross-border flows optimize costs** - Interconnectors enable cheap power to flow to expensive regions
16. **Carbon pricing affects dispatch** - EU ETS makes coal expensive, favors gas and renewables
17. **Frequency must stay at 50 Hz** - Real-time balancing essential for grid stability
18. **Capacity markets ensure reliability** - Pay plants to be available even when not running
19. **Day-ahead, intraday, and balancing work together** - Progressive refinement toward real-time
20. **ICE dominates European power trading** - Largest liquidity for hedging and speculation

---

**This knowledge helps you understand WHY the data you're processing is so critical to traders and risk managers!**
