# Nutrify-AI Setup Guide

## Prerequisites
- Python 3.10+
- PostgreSQL 14+
- Redis 6+
- Flutter 3.0+
- Stripe Account
- OpenAI API Key

## Backend Setup

### 1. Environment Variables
Create a `.env` file in the `backend/` directory:

```bash
# Application
APP_NAME=Nutrify-AI
APP_VERSION=1.0.0
ENVIRONMENT=development
DEBUG=true
HOST=0.0.0.0
PORT=8000
RELOAD=true
LOG_LEVEL=INFO

# Database
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/nutrify_db

# Redis
REDIS_URL=redis://localhost:6379/0

# Security
SECRET_KEY=your-secret-key-here-generate-with-openssl-rand-hex-32
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# OpenAI
OPENAI_API_KEY=your-openai-api-key

# Stripe
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# Google OAuth (Optional)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# AWS S3 (for future use)
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_S3_BUCKET=nutrify-uploads

# CORS
CORS_ORIGINS=["http://localhost:3000", "http://localhost:5173"]
```

### 2. Install Dependencies
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Database Setup
```bash
# Create database
createdb nutrify_db

# Run migrations
alembic upgrade head
```

### 4. Start Backend Server
```bash
# Development mode
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or use the main.py directly
python app/main.py
```

Backend will be available at: `http://localhost:8000`
API documentation: `http://localhost:8000/docs`

## Frontend (Flutter) Setup

### 1. Install Dependencies
```bash
cd flutter_app
flutter pub get
```

### 2. Configuration
Update the API base URL in `lib/services/api_service.dart`:
```dart
// For Android Emulator
static const String _baseUrl = 'http://10.0.2.2:8000/api/v1';

// For iOS Simulator
static const String _baseUrl = 'http://localhost:8000/api/v1';

// For physical devices (use your machine's IP)
static const String _baseUrl = 'http://192.168.x.x:8000/api/v1';
```

### 3. Run Flutter App
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web
flutter run -d chrome
```

## Stripe Setup

### 1. Create Stripe Account
1. Go to https://stripe.com and sign up
2. Get your test API keys from Dashboard → Developers → API keys

### 2. Configure Webhook
1. Go to Developers → Webhooks
2. Add endpoint: `https://your-domain.com/api/v1/subscriptions/webhook`
3. Select events to listen:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
4. Copy the webhook signing secret

### 3. Test Webhook Locally (Optional)
```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to local server
stripe listen --forward-to localhost:8000/api/v1/subscriptions/webhook
```

## Testing the New Features

### 1. Test Progress API CRUD
```bash
# Get progress entries
curl -X GET "http://localhost:8000/api/v1/progress?days=30" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Update progress entry by ID
curl -X PUT "http://localhost:8000/api/v1/progress/ENTRY_ID" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"weight": 75.5, "notes": "Feeling great!"}'

# Delete progress entry
curl -X DELETE "http://localhost:8000/api/v1/progress/ENTRY_ID" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. Test Subscription Flow
```bash
# Create checkout session
curl -X POST "http://localhost:8000/api/v1/subscriptions/checkout" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tier": "premium",
    "billing_period": "monthly",
    "success_url": "http://localhost:3000/success",
    "cancel_url": "http://localhost:3000/cancel"
  }'

# Get current subscription
curl -X GET "http://localhost:8000/api/v1/subscriptions/current" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Test OCR Food Logging
```bash
# Analyze food image
curl -X POST "http://localhost:8000/api/v1/nutrition/analyze-food-image" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/food-image.jpg"

# Get food suggestions
curl -X GET "http://localhost:8000/api/v1/nutrition/food-suggestions?query=chicken" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. Test Token Refresh
The token refresh happens automatically in the Flutter app when a 401 error is received. To test:
1. Wait for token to expire (30 minutes by default)
2. Make any API request
3. The app should automatically refresh the token and retry the request

## Database Migrations

### Create New Migration
```bash
cd backend
alembic revision -m "description_of_changes"
```

### Apply Migrations
```bash
alembic upgrade head
```

### Rollback Migration
```bash
alembic downgrade -1
```

## Troubleshooting

### Backend Issues

**Database Connection Error**
```bash
# Check PostgreSQL is running
pg_isready

# Check connection string
echo $DATABASE_URL
```

**Redis Connection Error**
```bash
# Check Redis is running
redis-cli ping
# Should return: PONG
```

**Import Errors**
```bash
# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### Flutter Issues

**Dependency Conflicts**
```bash
flutter pub cache repair
flutter clean
flutter pub get
```

**Platform-Specific Issues**
```bash
# iOS
cd ios && pod install && cd ..

# Android
flutter clean && flutter build apk
```

## Next Steps

1. **Set up environment variables** - Copy the template above and fill in your keys
2. **Run database migrations** - `alembic upgrade head`
3. **Start the backend** - `python app/main.py`
4. **Test the API** - Visit `http://localhost:8000/docs`
5. **Start Flutter app** - `flutter run`
6. **Test new features** - Use the curl commands above

## Production Deployment

### Backend
- Use gunicorn or uvicorn workers
- Set up proper CORS origins
- Enable HTTPS
- Use production database
- Set `DEBUG=false`
- Configure Sentry for error tracking

### Frontend
- Build release version: `flutter build apk --release`
- Update API base URL to production
- Configure proper deep linking for OAuth
- Set up Firebase for push notifications

### Infrastructure
- Use Docker containers for deployment
- Set up CI/CD pipeline (GitHub Actions)
- Configure CDN for static assets
- Set up monitoring and logging
- Use environment-specific configurations

## Support

For issues or questions:
1. Check the documentation in `/docs`
2. Review the PRD: `docs/Nutrify-AI_PRD.md`
3. Check implementation status: `docs/IMPLEMENTATION_STATUS.md`
4. Create an issue in the repository
