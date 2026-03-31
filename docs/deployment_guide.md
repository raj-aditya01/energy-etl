# 🚀 Deployment Guide

## Overview

This guide covers deploying the Energy ETL system to production environments, including AWS, containerization, monitoring, and operational best practices.

---

## 📋 Pre-Deployment Checklist

### ✅ Code Quality
- [ ] All tests passing (unit, integration, e2e)
- [ ] Code coverage > 80%
- [ ] Linting passes (black, flake8, mypy)
- [ ] Security scan completed (bandit, safety)
- [ ] Dependencies up to date

### ✅ Configuration
- [ ] Environment variables configured
- [ ] Secrets stored in AWS Secrets Manager
- [ ] Database connection strings updated
- [ ] API rate limits configured
- [ ] Logging levels set appropriately

### ✅ Database
- [ ] Migration scripts tested
- [ ] Backup strategy implemented
- [ ] Indexes optimized
- [ ] Connection pooling configured
- [ ] Read replicas set up (if needed)

### ✅ Monitoring
- [ ] CloudWatch alarms configured
- [ ] Error tracking enabled (Sentry)
- [ ] Performance metrics dashboard created
- [ ] Log aggregation configured
- [ ] Uptime monitoring active

---

## 🏗️ Architecture Overview

### Production Environment

```
┌─────────────────────────────────────────────────────────┐
│                      AWS CLOUD                          │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Application Load Balancer            │  │
│  │           (HTTPS: api.veraxion.com)              │  │
│  └────────────────┬─────────────────────────────────┘  │
│                   │                                     │
│  ┌────────────────┴─────────────────────────────────┐  │
│  │           ECS Fargate Cluster                     │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐       │  │
│  │  │ FastAPI  │  │ FastAPI  │  │ FastAPI  │       │  │
│  │  │Container │  │Container │  │Container │       │  │
│  │  │ (Task 1) │  │ (Task 2) │  │ (Task 3) │       │  │
│  │  └──────────┘  └──────────┘  └──────────┘       │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         AWS RDS PostgreSQL (Primary)             │  │
│  │         Instance: db.r6g.xlarge                  │  │
│  │         Multi-AZ: Yes                            │  │
│  │         Automated Backups: Daily                 │  │
│  └────────────────┬─────────────────────────────────┘  │
│                   │                                     │
│  ┌────────────────┴─────────────────────────────────┐  │
│  │         RDS Read Replica (us-east-1a)            │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │              S3 Buckets                          │  │
│  │  - energy-etl-raw-data (CSV files)              │  │
│  │  - energy-etl-backups (DB backups)              │  │
│  │  - energy-etl-logs (Application logs)           │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │          CloudWatch / Monitoring                 │  │
│  │  - Logs, Metrics, Alarms, Dashboards            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 🐳 Docker Containerization

### Dockerfile (Production)

Create `Dockerfile` in project root:

```dockerfile
# Multi-stage build for optimized image size
FROM python:3.11-slim as builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Final stage
FROM python:3.11-slim

# Install PostgreSQL client
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 appuser

# Copy Python dependencies from builder
COPY --from=builder /root/.local /home/appuser/.local

# Set working directory
WORKDIR /app

# Copy application code
COPY --chown=appuser:appuser src/ ./src/
COPY --chown=appuser:appuser alembic/ ./alembic/
COPY --chown=appuser:appuser alembic.ini .

# Switch to non-root user
USER appuser

# Add local bin to PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8000/health')"

# Run application
CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### Build and Push to ECR

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

# Build image
docker build -t energy-etl:latest .

# Tag image
docker tag energy-etl:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/energy-etl:latest
docker tag energy-etl:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/energy-etl:v1.0.0

# Push to ECR
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/energy-etl:latest
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/energy-etl:v1.0.0
```

---

## ☁️ AWS Infrastructure Setup

### 1. VPC Configuration

```bash
# Create VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=energy-etl-vpc}]'

# Create subnets (public and private)
aws ec2 create-subnet --vpc-id vpc-xxxxx --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id vpc-xxxxx --cidr-block 10.0.2.0/24 --availability-zone us-east-1b

# Create Internet Gateway
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --vpc-id vpc-xxxxx --internet-gateway-id igw-xxxxx
```

### 2. RDS PostgreSQL Setup

```bash
# Create DB subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name energy-etl-db-subnet \
  --db-subnet-group-description "Subnet group for Energy ETL" \
  --subnet-ids subnet-xxxxx subnet-yyyyy

# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier energy-etl-prod \
  --db-instance-class db.r6g.xlarge \
  --engine postgres \
  --engine-version 16.1 \
  --master-username admin \
  --master-user-password "STORED_IN_SECRETS_MANAGER" \
  --allocated-storage 100 \
  --storage-type gp3 \
  --storage-encrypted \
  --multi-az \
  --db-subnet-group-name energy-etl-db-subnet \
  --vpc-security-group-ids sg-xxxxx \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "mon:04:00-mon:05:00" \
  --enable-performance-insights \
  --auto-minor-version-upgrade
```

### 3. S3 Buckets

```bash
# Create S3 buckets
aws s3 mb s3://energy-etl-raw-data --region us-east-1
aws s3 mb s3://energy-etl-backups --region us-east-1
aws s3 mb s3://energy-etl-logs --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket energy-etl-raw-data \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket energy-etl-raw-data \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Lifecycle policy (delete old files after 90 days)
aws s3api put-bucket-lifecycle-configuration \
  --bucket energy-etl-raw-data \
  --lifecycle-configuration file://s3-lifecycle.json
```

### 4. ECS Fargate Cluster

```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name energy-etl-cluster

# Create task definition
aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json

# Create ECS service
aws ecs create-service \
  --cluster energy-etl-cluster \
  --service-name energy-etl-api \
  --task-definition energy-etl-task:1 \
  --desired-count 3 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx,subnet-yyyyy],securityGroups=[sg-xxxxx],assignPublicIp=DISABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=energy-etl-api,containerPort=8000"
```

**ECS Task Definition (`ecs-task-definition.json`):**

```json
{
  "family": "energy-etl-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "executionRoleArn": "arn:aws:iam::123456789:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456789:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "energy-etl-api",
      "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/energy-etl:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "ENVIRONMENT", "value": "production"},
        {"name": "LOG_LEVEL", "value": "INFO"}
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:energy-etl/db-url"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/energy-etl",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

### 5. Application Load Balancer

```bash
# Create ALB
aws elbv2 create-load-balancer \
  --name energy-etl-alb \
  --subnets subnet-xxxxx subnet-yyyyy \
  --security-groups sg-xxxxx \
  --scheme internet-facing \
  --type application

# Create target group
aws elbv2 create-target-group \
  --name energy-etl-tg \
  --protocol HTTP \
  --port 8000 \
  --vpc-id vpc-xxxxx \
  --target-type ip \
  --health-check-path /health \
  --health-check-interval-seconds 30

# Create listener (HTTPS)
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:... \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=arn:aws:acm:... \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:...
```

---

## 🔐 Secrets Management

### AWS Secrets Manager

```bash
# Store database credentials
aws secretsmanager create-secret \
  --name energy-etl/db-credentials \
  --description "PostgreSQL database credentials" \
  --secret-string '{
    "username": "admin",
    "password": "SECURE_PASSWORD_HERE",
    "host": "energy-etl-prod.xxxxx.us-east-1.rds.amazonaws.com",
    "port": 5432,
    "database": "energy_production"
  }'

# Store API keys
aws secretsmanager create-secret \
  --name energy-etl/api-keys \
  --secret-string '{
    "master_key": "MASTER_API_KEY_HERE",
    "read_only_key": "READONLY_API_KEY_HERE"
  }'
```

### Environment Variables

Create `.env.production` (never commit to git):

```bash
# Application
ENVIRONMENT=production
APP_NAME=energy-etl
VERSION=1.0.0

# Database
DATABASE_URL=postgresql://admin:password@energy-etl-prod.xxxxx.us-east-1.rds.amazonaws.com:5432/energy_production
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=10
DB_POOL_TIMEOUT=30

# API
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4
API_RATE_LIMIT=100

# S3
S3_BUCKET_RAW_DATA=energy-etl-raw-data
S3_BUCKET_BACKUPS=energy-etl-backups
AWS_REGION=us-east-1

# Logging
LOG_LEVEL=INFO
LOG_FORMAT=json
SENTRY_DSN=https://xxxxx@sentry.io/xxxxx

# Monitoring
ENABLE_METRICS=true
METRICS_PORT=9090
```

---

## 📊 Database Migration

### Using Alembic

```bash
# Generate migration
alembic revision --autogenerate -m "Initial production schema"

# Review migration file
cat alembic/versions/xxxxx_initial_production_schema.py

# Test migration (staging)
alembic upgrade head

# Backup before production migration
pg_dump -h energy-etl-prod.xxxxx.rds.amazonaws.com -U admin -d energy_production > backup_pre_migration.sql

# Run production migration
alembic upgrade head

# Verify migration
psql -h energy-etl-prod.xxxxx.rds.amazonaws.com -U admin -d energy_production -c "\dt analytics.*"
```

---

## 🔍 Monitoring & Observability

### CloudWatch Alarms

```bash
# High CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name energy-etl-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:123456789:energy-etl-alerts

# High error rate alarm
aws cloudwatch put-metric-alarm \
  --alarm-name energy-etl-high-errors \
  --metric-name 5XXError \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --period 60 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:123456789:energy-etl-alerts
```

### CloudWatch Dashboard

Create `cloudwatch-dashboard.json`:

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", {"stat": "Average"}],
          [".", "MemoryUtilization", {"stat": "Average"}]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "ECS Resources"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/RDS", "DatabaseConnections"],
          [".", "CPUUtilization"],
          [".", "FreeableMemory"]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "RDS Metrics"
      }
    }
  ]
}
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      
      - name: Run tests
        run: pytest tests/ --cov=src --cov-report=xml
      
      - name: Run linters
        run: |
          black --check src/
          flake8 src/
          mypy src/

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build and push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: energy-etl
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster energy-etl-cluster \
            --service energy-etl-api \
            --force-new-deployment
```

---

## 🔥 Deployment Steps

### Production Deployment Checklist

1. **Pre-Deployment**
   ```bash
   # Run full test suite
   pytest tests/ -v
   
   # Database backup
   ./scripts/backup_database.sh production
   
   # Tag release
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. **Deploy**
   ```bash
   # Trigger GitHub Actions
   git push origin main
   
   # Or manual deployment
   ./scripts/deploy_production.sh
   ```

3. **Verify Deployment**
   ```bash
   # Check service status
   aws ecs describe-services --cluster energy-etl-cluster --services energy-etl-api
   
   # Test health endpoint
   curl https://api.veraxion.com/health
   
   # Check logs
   aws logs tail /ecs/energy-etl --follow
   ```

4. **Post-Deployment**
   ```bash
   # Run smoke tests
   pytest tests/smoke/ --url=https://api.veraxion.com
   
   # Monitor metrics
   # Check CloudWatch dashboard
   
   # Verify data quality
   curl https://api.veraxion.com/api/v1/quality/report
   ```

---

## 🔙 Rollback Procedure

```bash
# List previous task definitions
aws ecs list-task-definitions --family-prefix energy-etl-task

# Update service to previous version
aws ecs update-service \
  --cluster energy-etl-cluster \
  --service energy-etl-api \
  --task-definition energy-etl-task:PREVIOUS_VERSION

# Verify rollback
aws ecs describe-services --cluster energy-etl-cluster --services energy-etl-api
```

---

## 📈 Scaling Configuration

### Auto Scaling

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/energy-etl-cluster/energy-etl-api \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 10

# Create scaling policy (CPU-based)
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id service/energy-etl-cluster/energy-etl-api \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name cpu-scaling-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://scaling-policy.json
```

**scaling-policy.json:**
```json
{
  "TargetValue": 70.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "ScaleInCooldown": 300,
  "ScaleOutCooldown": 60
}
```

---

## 🎯 Performance Optimization

### Database Connection Pooling

```python
# src/database/connection.py
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,  # Normal connection pool
    max_overflow=10,  # Allow up to 30 total connections
    pool_timeout=30,  # Wait 30s for connection
    pool_recycle=3600,  # Recycle connections after 1 hour
    pool_pre_ping=True  # Verify connections before use
)
```

### API Response Caching

```python
# Install Redis
pip install redis

# Implement caching
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend
from redis import asyncio as aioredis

@app.on_event("startup")
async def startup():
    redis = aioredis.from_url("redis://localhost")
    FastAPICache.init(RedisBackend(redis), prefix="energy-etl-cache")
```

---

## 📞 Support & Maintenance

**Deployment Support:**
- DevOps Team: devops@veraxion.com
- On-Call: +1-xxx-xxx-xxxx
- Slack: #energy-etl-deployments

**Monitoring Dashboards:**
- CloudWatch: https://console.aws.amazon.com/cloudwatch
- Grafana: https://grafana.veraxion.com
- Sentry: https://sentry.io/veraxion/energy-etl
