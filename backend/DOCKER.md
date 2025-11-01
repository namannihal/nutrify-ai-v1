# Docker Setup for Nutrify-AI Backend

## 🐳 Quick Start with Docker

### 1. Start Database Services

```bash
# Start PostgreSQL and Redis
docker compose up -d

# Or start with pgAdmin for database management
docker compose --profile dev up -d
```

### 2. Check Services Status

```bash
# View running containers
docker compose ps

# View logs
docker compose logs -f postgres
docker compose logs -f redis
```

### 3. Run Backend

```bash
# Setup and start backend (connects to Docker database)
./setup.sh
./start.sh
```

---

## 📦 Services Included

### PostgreSQL (Port 5432)
- **Image:** `postgres:15-alpine`
- **Database:** `nutrify_db`
- **User:** `nutrify_user`
- **Password:** `nutrify_password` (change in production!)
- **Volume:** `postgres_data` (persistent storage)

### Redis (Port 6379)
- **Image:** `redis:7-alpine`
- **Persistence:** Enabled (AOF)
- **Volume:** `redis_data` (persistent storage)

### pgAdmin (Port 5050) - Optional
- **Image:** `dpage/pgadmin4`
- **Email:** `admin@nutrify.ai`
- **Password:** `admin`
- **Access:** http://localhost:5050
- **Note:** Only starts with `--profile dev`

---

## 🔧 Docker Commands

### Starting Services

```bash
# Start all services
docker compose up -d

# Start specific services
docker compose up -d postgres redis

# Start with pgAdmin
docker compose --profile dev up -d

# View startup logs
docker compose logs -f
```

### Stopping Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes (⚠️ deletes data!)
docker compose down -v
```

### Managing Containers

```bash
# Restart services
docker compose restart

# View container status
docker compose ps

# View logs
docker compose logs postgres
docker compose logs redis

# Follow logs
docker compose logs -f postgres
```

### Database Operations

```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U nutrify_user -d nutrify_db

# Backup database
docker compose exec postgres pg_dump -U nutrify_user nutrify_db > backup.sql

# Restore database
docker compose exec -T postgres psql -U nutrify_user -d nutrify_db < backup.sql

# Access PostgreSQL shell
docker compose exec postgres bash
```

### Redis Operations

```bash
# Connect to Redis CLI
docker compose exec redis redis-cli

# Check Redis info
docker compose exec redis redis-cli INFO

# Clear Redis cache
docker compose exec redis redis-cli FLUSHALL
```

---

## 🔐 pgAdmin Setup (Optional)

### 1. Start pgAdmin

```bash
docker compose --profile dev up -d
```

### 2. Access pgAdmin

Open http://localhost:5050

- **Email:** `admin@nutrify.ai`
- **Password:** `admin`

### 3. Add Server Connection

1. Right-click "Servers" → "Register" → "Server"
2. **General Tab:**
   - Name: `Nutrify-AI`
3. **Connection Tab:**
   - Host: `postgres` (container name)
   - Port: `5432`
   - Username: `nutrify_user`
   - Password: `nutrify_password`
   - Save password: ✓

---

## 🌐 Environment Configuration

Update your `.env` file based on your setup:

### Option 1: Backend Running Locally (Recommended for Development)

```env
# Use localhost since backend connects from host machine
DATABASE_URL=postgresql+asyncpg://nutrify_user:nutrify_password@localhost:5432/nutrify_db
REDIS_URL=redis://localhost:6379/0
```

### Option 2: Backend Running in Docker Container

```env
# Use container names (if backend runs in Docker network)
DATABASE_URL=postgresql+asyncpg://nutrify_user:nutrify_password@postgres:5432/nutrify_db
REDIS_URL=redis://redis:6379/0
```

---

## 🔍 Health Checks

Docker containers include health checks:

```bash
# Check PostgreSQL health
docker compose exec postgres pg_isready -U nutrify_user

# Check Redis health
docker compose exec redis redis-cli ping
```

Expected responses:
- PostgreSQL: `accepting connections`
- Redis: `PONG`

---

## 📊 Monitoring

### View Resource Usage

```bash
# Container stats
docker stats nutrify-postgres nutrify-redis

# Disk usage
docker system df
```

### Volume Information

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect nutrify-v2_postgres_data

# Volume usage
docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}"
```

---

## 🧹 Cleanup

### Remove Containers (Keep Data)

```bash
docker compose down
```

### Remove Everything (⚠️ Including Data)

```bash
# Remove containers and volumes
docker compose down -v

# Remove images
docker rmi postgres:15-alpine redis:7-alpine
```

### Clean Docker System

```bash
# Remove unused data
docker system prune -a

# Remove unused volumes
docker volume prune
```

---

## 🔄 Data Persistence

Data is persisted in Docker volumes:

- `nutrify-v2_postgres_data` - PostgreSQL data
- `nutrify-v2_redis_data` - Redis data
- `nutrify-v2_pgadmin_data` - pgAdmin settings

These volumes survive container restarts and removals (unless you use `-v` flag).

---

## 🚀 Production Considerations

### Security

```yaml
# Update docker-compose.yml for production:
services:
  postgres:
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}  # Use secrets
    # Don't expose port publicly in production
    # Remove: ports: - "5432:5432"
```

### Backups

```bash
# Automated backup script
#!/bin/bash
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
docker compose exec -T postgres pg_dump -U nutrify_user nutrify_db > "$BACKUP_DIR/nutrify_db_$TIMESTAMP.sql"
```

### Resource Limits

```yaml
services:
  postgres:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

---

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Find process using port 5432
lsof -ti:5432 | xargs kill -9

# Or change port in docker-compose.yml
ports:
  - "5433:5432"  # External:Internal
```

### Connection Refused

1. Check container is running: `docker compose ps`
2. Check logs: `docker compose logs postgres`
3. Verify health: `docker compose exec postgres pg_isready`
4. Check firewall settings

### Permission Denied

```bash
# Fix volume permissions
docker compose down
docker volume rm nutrify-v2_postgres_data
docker compose up -d
```

### Container Won't Start

```bash
# View detailed logs
docker compose logs postgres

# Recreate container
docker compose up -d --force-recreate postgres
```

---

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [Redis Docker Hub](https://hub.docker.com/_/redis)
- [pgAdmin Docker](https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html)

---

**Ready to develop! 🎉**
