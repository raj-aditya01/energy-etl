# 🚀 QUICK START GUIDE
## Energy Trading Settlement Prices ETL Project

**Welcome!** This is your roadmap to get started with the project.

---

## ⚡ 5-Minute Setup

### 1️⃣ Start PostgreSQL
```bash
# Start the database container
docker-compose up -d

# Verify it's running
docker-compose ps
```

### 2️⃣ Create Database Schemas
```bash
# Run the setup script
docker-compose exec postgres psql -U learner -d energy_learning -f docs/setup_database.sql

# You should see: ✅ Database setup complete!
```

### 3️⃣ Verify Everything Works
```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U learner -d energy_learning

# Inside psql, run:
\dn                                    # List schemas (should see raw_data, staging, analytics, audit)
\dt analytics.*                        # List tables in analytics schema
SELECT * FROM analytics.market_prices; # View sample data
\q                                     # Quit
```

---

## 📚 What to Read First

### For Beginners (Start Here!)
1. **docs/PROJECT_OVERVIEW.md** (30 minutes)
   - Understand what you're building
   - See visual architecture diagrams
   - Learn key concepts

### For Developers
2. **docs/IMPLEMENTATION_PLAN.md** (60 minutes)
   - Complete technical specifications
   - Database design deep dive
   - API endpoint details
   - Best practices

### For Database Setup
3. **docs/setup_database.sql** (Reference)
   - All table definitions
   - Indexes and constraints
   - Sample data

---

## 🎯 Your First Tasks

### Week 1: Foundation
**Todo:** `setup-project-structure`
- Create folder structure (src/, tests/, scripts/)
- Setup Python project (requirements.txt, pyproject.toml)
- Initialize Git repository

**Todo:** `create-database-schemas` ✅ (Already done!)
- You already ran setup_database.sql
- All schemas and tables created

**Todo:** `setup-logging-config`
- Configure structured JSON logging
- Setup log rotation

**Todo:** `create-ci-cd-pipeline`
- GitHub Actions workflows
- Pytest, black, flake8, mypy

### Check Your Progress
```bash
# Query ready tasks from SQL database
# (You'll set this up in the orchestration layer)
```

---

## 🗂️ File Locations

| File | Location | Purpose |
|------|----------|---------|
| **Full Technical Plan** | `docs/IMPLEMENTATION_PLAN.md` | Complete architecture, 33 todos |
| **Visual Learning Guide** | `docs/PROJECT_OVERVIEW.md` | Easy-to-understand overview |
| **Database Setup** | `docs/setup_database.sql` | Create all schemas/tables |
| **Documentation Index** | `docs/README.md` | Guide to all docs |
| **This Quick Start** | `QUICKSTART.md` | You are here! |
| **PostgreSQL Config** | `docker-compose.yaml` | Database container setup |

---

## 🔧 Useful Commands

### Docker & PostgreSQL
```bash
# Start database
docker-compose up -d

# Stop database (keeps data)
docker-compose stop

# Stop and remove (keeps data)
docker-compose down

# Stop and DELETE ALL DATA
docker-compose down -v

# View logs
docker-compose logs -f postgres

# Connect to psql
docker-compose exec postgres psql -U learner -d energy_learning

# Run SQL file
docker-compose exec postgres psql -U learner -d energy_learning -f path/to/file.sql
```

### PostgreSQL Commands (inside psql)
```sql
-- List all databases
\l

-- List all schemas
\dn

-- List tables in a schema
\dt raw_data.*
\dt staging.*
\dt analytics.*
\dt audit.*

-- Describe a table
\d analytics.market_prices

-- View sample data
SELECT * FROM analytics.market_prices LIMIT 5;

-- Count records
SELECT 
    'raw_data' as schema, COUNT(*) FROM raw_data.settlement_prices_raw
UNION ALL
SELECT 'staging', COUNT(*) FROM staging.settlement_prices_staging
UNION ALL
SELECT 'analytics', COUNT(*) FROM analytics.market_prices;

-- Exit psql
\q
```

---

## 📖 Learning Resources

### PostgreSQL Learning
- [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)
- Schema design concepts in `docs/IMPLEMENTATION_PLAN.md`
- All SQL commented in `docs/setup_database.sql`

### Python ETL
- Pandas documentation
- SQLAlchemy ORM patterns
- Pydantic validation

### FastAPI
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- API design in `docs/IMPLEMENTATION_PLAN.md`

---

## 🎓 Key Concepts

### ETL Pipeline
1. **Extract** - Pull data from source (S3/CSV)
2. **Transform** - Clean, validate, enrich
3. **Load** - Insert into production table

### 4-Schema Design
1. **raw_data** - Immutable landing zone (CSV as-is)
2. **staging** - Cleaned & validated
3. **analytics** - Production tables (what users read)
4. **audit** - Logs and quality checks

### Data Quality
- **Completeness** - No missing required fields
- **Accuracy** - Values in valid ranges
- **Consistency** - No duplicates
- **Timeliness** - Data is fresh

---

## ✅ Success Checklist

### Database Setup ✅
- [ ] PostgreSQL running (`docker-compose ps`)
- [ ] Schemas created (raw_data, staging, analytics, audit)
- [ ] Sample data visible (`SELECT * FROM analytics.market_prices`)
- [ ] Can connect via psql

### Documentation Read
- [ ] Read PROJECT_OVERVIEW.md
- [ ] Reviewed IMPLEMENTATION_PLAN.md
- [ ] Understand the 4-schema design
- [ ] Know the 33 implementation tasks

### Ready to Code
- [ ] Python virtual environment activated
- [ ] Understand ETL flow
- [ ] Know where to start (Phase 1: Foundation)
- [ ] Ready to implement first todo

---

## 🚨 Troubleshooting

### Database won't start
```bash
# Check if port 5432 is already in use
docker-compose down
docker-compose up -d

# View logs for errors
docker-compose logs postgres
```

### Can't connect to PostgreSQL
```bash
# Verify container is running
docker-compose ps

# Check connection settings in docker-compose.yaml
# User: learner
# Password: learning123
# Database: energy_learning
# Port: 5432
```

### Schema creation fails
```bash
# Drop and recreate (WARNING: Deletes all data!)
docker-compose exec postgres psql -U learner -d energy_learning

# In psql:
DROP SCHEMA IF EXISTS raw_data CASCADE;
DROP SCHEMA IF EXISTS staging CASCADE;
DROP SCHEMA IF EXISTS analytics CASCADE;
DROP SCHEMA IF EXISTS audit CASCADE;

# Then re-run setup_database.sql
```

---

## 🎯 Next Steps

1. ✅ **Setup Complete** - You've already done this!
2. 📖 **Read Docs** - Start with PROJECT_OVERVIEW.md
3. 💻 **Start Coding** - Begin with `setup-project-structure` todo
4. 🧪 **Test** - Write tests as you implement
5. 📊 **Monitor** - Add logging and metrics
6. 🚀 **Deploy** - Follow deployment guide

---

## 💬 Need Help?

- **Architecture Questions:** Read `docs/IMPLEMENTATION_PLAN.md`
- **Concept Explanations:** Check `docs/PROJECT_OVERVIEW.md`
- **Database Issues:** Review `docs/setup_database.sql` comments
- **Getting Started:** You're reading it! (QUICKSTART.md)

---

## 🎉 You're Ready!

Your database is set up, documentation is complete, and you have a clear roadmap. Time to start building! 💪

**First task:** Read `docs/PROJECT_OVERVIEW.md` to understand what you're building and why.

**Happy coding!** 🚀
