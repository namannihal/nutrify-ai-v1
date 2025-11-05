# Nutrify-AI Database Setup Guide

## Recommended: Supabase + Render + GitHub Pages

### Why Supabase?
- ✅ 500MB free forever (no 90-day limit)
- ✅ Full PostgreSQL with extensions
- ✅ Great dashboard for monitoring
- ✅ Easy connection to Render backend
- ✅ Built-in auth (optional future feature)

### Setup Steps:

1. **Create Supabase Database:**
   - Go to supabase.com → New Project
   - Choose region (closest to your users)
   - Copy connection string from Settings → Database

2. **Configure Render Backend:**
   - Environment Variables → Add:
     DATABASE_URL=postgresql://postgres:[password]@[host]:5432/postgres
     ENVIRONMENT=production
     DEBUG=False
     CORS_ORIGINS=https://nutrify-me.github.io

3. **Update Frontend API URL:**
   - GitHub repository → Settings → Secrets
   - Update VITE_API_URL to your Render backend URL

### Architecture Flow:
```
User Browser
    ↓
GitHub Pages (Frontend)
    ↓ API calls to https://your-app.onrender.com
Render (Backend)
    ↓ PostgreSQL connection
Supabase Database
```

### Connection String Format:
postgresql://postgres:YOUR_PASSWORD@HOST:5432/postgres

### Migration Strategy:
1. Start with Supabase free tier
2. If you outgrow 500MB, upgrade Supabase ($25/month)
3. Alternative: Switch to Render DB when you're ready to pay

### Security Notes:
- Database is private (only backend can access)
- Frontend never connects directly to database
- All data flows through your secure FastAPI backend