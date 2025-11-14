# VPS Deployment Troubleshooting Guide

## Issue: Backend Cannot Connect to Supabase

### Root Causes & Solutions

#### 1. **Network Configuration** ✅ FIXED
**Problem**: Using `network_mode: "host"` breaks Docker networking on VPS
**Solution**: Removed host networking, backend now uses bridge network

#### 2. **VPS Firewall Rules**

Check if outbound PostgreSQL connections are allowed:

```bash
# On VPS, check firewall status
sudo ufw status

# Allow outbound connections to Supabase (port 5432)
sudo ufw allow out 5432/tcp

# If using iptables
sudo iptables -L OUTPUT -v -n | grep 5432
```

#### 3. **Test Supabase Connectivity**

Before starting Docker, test direct connection:

```bash
# Install PostgreSQL client on VPS
sudo apt-get update && sudo apt-get install -y postgresql-client

# Test connection to Supabase
psql "postgresql://postgres:iCvrbaJHMiM97Vw6@db.sisnrhostkpolotacnjj.supabase.co:5432/postgres?sslmode=require"

# If connection fails, check DNS resolution
nslookup db.sisnrhostkpolotacnjj.supabase.co

# Test TCP connection
telnet db.sisnrhostkpolotacnjj.supabase.co 5432
# OR
nc -zv db.sisnrhostkpolotacnjj.supabase.co 5432
```

#### 4. **Docker Network Debugging**

```bash
# Check if backend container can reach internet
docker exec -it nutrify-v2-backend-1 ping -c 3 8.8.8.8

# Check DNS resolution inside container
docker exec -it nutrify-v2-backend-1 nslookup db.sisnrhostkpolotacnjj.supabase.co

# Test PostgreSQL connection from inside container
docker exec -it nutrify-v2-backend-1 nc -zv db.sisnrhostkpolotacnjj.supabase.co 5432
```

#### 5. **Supabase IP Allowlist** (If Required)

Some Supabase projects restrict connections to specific IPs:

1. Get your VPS public IP:
   ```bash
   curl ifconfig.me
   ```

2. Add to Supabase allowlist:
   - Go to: https://app.supabase.com/project/sisnrhostkpolotacnjj/settings/database
   - Navigate to "Connection Security"
   - Add your VPS IP to allowlist

#### 6. **Check Backend Logs**

```bash
# View backend container logs
docker compose logs backend -f

# Look for these error patterns:
# - "Network is unreachable" → Firewall/routing issue
# - "Connection refused" → Supabase blocking connection
# - "SSL required" → SSL configuration missing
# - "timeout" → Network latency or DNS issue
```

#### 7. **Environment Variables on VPS**

Ensure `.env` file is properly uploaded to VPS:

```bash
# On VPS, verify .env exists
cat backend/.env | grep DATABASE_URL

# Should output:
# DATABASE_URL=postgresql+asyncpg://postgres:iCvrbaJHMiM97Vw6@db.sisnrhostkpolotacnjj.supabase.co:5432/postgres?ssl=require
```

#### 8. **Updated Redis Configuration**

The docker-compose.yml now overrides `REDIS_URL` to use Docker service name:
- **Local `.env`**: `redis://localhost:6380/0` (for host networking)
- **Docker override**: `redis://redis:6379/0` (for bridge networking)

This ensures Redis connectivity works in Docker without modifying `.env`.

## Deployment Steps (Updated)

```bash
# 1. On VPS, clone repository
git clone https://github.com/nutrify-me/nutrify-ai-v1.git
cd nutrify-ai-v1
git checkout users/naman/backend-frontend-infra

# 2. Copy .env file (from local machine)
scp backend/.env user@vps-ip:/path/to/nutrify-ai-v1/backend/.env

# 3. Test Supabase connectivity BEFORE Docker
psql "postgresql://postgres:iCvrbaJHMiM97Vw6@db.sisnrhostkpolotacnjj.supabase.co:5432/postgres?sslmode=require"

# 4. If connection works, start Docker services
docker compose up -d --build

# 5. Monitor logs
docker compose logs backend -f

# 6. Test health endpoint
curl http://localhost:8000/health
```

## Common Error Messages & Fixes

| Error | Cause | Solution |
|-------|-------|----------|
| `Network is unreachable` | VPS firewall blocking | `sudo ufw allow out 5432/tcp` |
| `Connection timed out` | DNS or routing issue | Check `nslookup` and `traceroute` |
| `Connection refused` | Supabase IP allowlist | Add VPS IP to Supabase settings |
| `SSL required` | Missing SSL parameter | Already fixed in `DATABASE_URL` |
| `Redis connection failed` | Wrong Redis URL | Use `redis://redis:6379/0` in Docker |

## Success Indicators

✅ Backend container starts without errors
✅ Health endpoint returns 200: `http://VPS_IP:8000/health`
✅ API docs accessible: `http://VPS_IP:8000/docs`
✅ Backend logs show: `"Application startup complete"`
✅ No SSL or connection errors in logs

## Production Hardening (After Successful Connection)

1. **Change to production mode**:
   ```bash
   # In backend/.env
   ENVIRONMENT=production
   DEBUG=False
   RELOAD=False
   ```

2. **Use environment secrets** (Azure Key Vault or similar)

3. **Enable HTTPS** with Nginx reverse proxy + Let's Encrypt

4. **Restrict database access** to VPS IP only

5. **Setup monitoring** (health checks, alerts)

---

**Last Updated**: 2025-11-15
**Status**: Network configuration fixed, ready for VPS deployment
