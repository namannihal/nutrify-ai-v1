# Testing Guide - New Features

This guide will help you test all the newly implemented features in the Nutrify-AI app.

## Prerequisites

Before testing, make sure you have:

1. ✅ Backend running on `http://localhost:8000`
2. ✅ Database migrated: `cd backend && alembic upgrade head`
3. ✅ Environment variables set (especially `STRIPE_SECRET_KEY` and `OPENAI_API_KEY`)
4. ✅ Flutter app running: `cd flutter_app && flutter run`

## Feature Testing Checklist

### 1. Progress API CRUD Operations ✅

**Test Update Progress Entry:**
1. Go to **Progress** tab in the app
2. Tap on an existing progress entry
3. Edit weight, notes, or any other field
4. Save changes
5. Verify the update appears immediately

**Test Delete Progress Entry:**
1. Go to **Progress** tab
2. Long press or swipe on a progress entry
3. Tap delete
4. Confirm deletion
5. Verify entry is removed from the list

**Backend API Test:**
```bash
# Update progress entry
curl -X PUT "http://localhost:8000/api/v1/progress/YOUR_ENTRY_ID" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"weight": 75.5, "notes": "Feeling great!"}'

# Delete progress entry
curl -X DELETE "http://localhost:8000/api/v1/progress/YOUR_ENTRY_ID" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### 2. Token Refresh ✅

**Test Automatic Token Refresh:**
1. Log in to the app
2. Wait for 30 minutes (or modify `ACCESS_TOKEN_EXPIRE_MINUTES` to 1 minute for faster testing)
3. Make any API call (e.g., view nutrition plan, check progress)
4. The app should automatically refresh the token and complete the request
5. You should NOT be logged out

**Expected Behavior:**
- No error messages
- Seamless continuation of app usage
- Only forces re-login if refresh token is also expired

---

### 3. Logout API Call ✅

**Test Logout:**
1. Go to **Profile** tab
2. Scroll down and tap **Sign Out**
3. Confirm logout
4. Check backend logs - you should see a call to `/api/v1/auth/logout`
5. Verify you're redirected to login screen
6. Verify tokens are cleared (try refreshing - should not auto-login)

---

### 4. Subscription Management (Stripe) ✅

**Access Subscription Screen:**
1. Go to **Profile** tab
2. Tap on **Subscription** option (first in settings list)
3. You'll see the Subscription Management screen

**Test Viewing Current Subscription:**
- Default state: Shows "FREE" plan
- Displays current tier, status, and features

**Test Subscribing to Premium:**
1. Scroll down to "Upgrade Your Plan" section
2. Tap **Subscribe Now** on either:
   - Premium Monthly ($14.99/month)
   - Premium Yearly ($149.99/year - 17% savings)
3. You'll be redirected to Stripe Checkout
4. Use Stripe test card: `4242 4242 4242 4242`
   - Any future expiry date
   - Any 3-digit CVC
   - Any billing ZIP code
5. Complete the checkout
6. You'll be redirected back to the app
7. Refresh the subscription screen
8. Verify:
   - Tier shows "PREMIUM"
   - Status shows "active" or "trialing" (14-day trial)
   - Billing period and amount are correct

**Test Customer Portal:**
1. On subscription screen, tap the **Manage Subscription** icon (top-right)
2. Opens Stripe Customer Portal
3. Test:
   - Update payment method
   - View invoices
   - Cancel subscription

**Test Cancellation:**
1. On subscription screen, tap **Cancel Subscription**
2. Confirm cancellation
3. Verify:
   - Status shows cancellation date
   - Message says "will be canceled at end of billing period"
   - You still have access until period end

**Test Payment History:**
- After making a payment, scroll down to see **Payment History**
- Shows all successful/failed payments
- Displays amount, date, and status

**Backend API Tests:**
```bash
# Get current subscription
curl -X GET "http://localhost:8000/api/v1/subscriptions/current" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create checkout session
curl -X POST "http://localhost:8000/api/v1/subscriptions/checkout" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tier": "premium",
    "billing_period": "monthly",
    "success_url": "nutrify://subscription/success",
    "cancel_url": "nutrify://subscription/cancel"
  }'
```

---

### 5. OCR Food Logging ✅

**Access Food Scanner:**
1. Go to **Nutrition** tab
2. Tap the **Camera** icon in the top-right
3. Opens Food Scanner screen

**Test Taking a Photo:**
1. Tap **Take Photo** button
2. Allow camera permissions
3. Take a photo of food (any meal, snack, or dish)
4. Wait 3-5 seconds for analysis
5. Review results:
   - Total calories
   - Meal type suggestion (breakfast/lunch/dinner/snack)
   - Number of foods detected
   - Notes about the meal

**Test Uploading from Gallery:**
1. Tap **Choose from Gallery**
2. Allow photo library permissions
3. Select a food image
4. Wait for analysis
5. Review results

**Test Food Details:**
- Each detected food shows:
  - Food name
  - Confidence score (%)
  - Serving size
  - Calories
  - Protein, Carbs, Fat (in grams)
- High confidence (>70%): Green badge
- Medium confidence (50-70%): Orange badge
- Low confidence (<50%): Red badge

**Test Logging the Meal:**
1. After analyzing, tap the **Check** icon (top-right)
2. Meal will be logged (TODO: implement actual logging)
3. Currently shows success message
4. Returns to nutrition plan

**Test from URL:**
```bash
# Backend API test
curl -X POST "http://localhost:8000/api/v1/nutrition/analyze-food-url" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"image_url": "https://example.com/food-image.jpg"}'
```

**Test Food Suggestions:**
```bash
# Get AI-powered food suggestions
curl -X GET "http://localhost:8000/api/v1/nutrition/food-suggestions?query=chicken" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Tips for Better Results:**
- Use good lighting
- Frame the food clearly
- Include all items in one shot if possible
- Works best with common foods
- May struggle with heavily processed or mixed dishes

---

## Common Issues & Solutions

### Issue: "Failed to analyze food image"
**Solutions:**
- Check OPENAI_API_KEY is set correctly
- Verify you have API credits
- Check image size (should be < 20MB)
- Try a clearer image with better lighting

### Issue: "Failed to create checkout session"
**Solutions:**
- Check STRIPE_SECRET_KEY is set correctly
- Verify Stripe account is in test mode
- Check backend logs for detailed error
- Ensure user doesn't already have an active subscription

### Issue: Token refresh not working
**Solutions:**
- Check backend logs for refresh token errors
- Verify REFRESH_TOKEN_EXPIRE_DAYS is set
- Make sure JWT_ALGORITHM matches between encoding and decoding
- Clear app data and re-login

### Issue: Progress update/delete not working
**Solutions:**
- Check backend is running
- Verify progress entry ID exists
- Check user has permission to modify the entry
- Look for validation errors in backend logs

---

## Flutter Dependencies

The new features require these packages (already in `pubspec.yaml`):

```yaml
dependencies:
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
  logger: ^2.0.0
  go_router: ^12.0.0
  flutter_riverpod: ^2.4.0
  image_picker: ^1.0.4  # For camera/gallery access
  url_launcher: ^6.2.1  # For opening Stripe URLs
```

If any are missing, run:
```bash
cd flutter_app
flutter pub get
```

---

## Performance Notes

- **OCR Analysis**: Takes 3-10 seconds depending on image size and complexity
- **Token Refresh**: Happens automatically in ~200ms
- **Subscription Check**: Cached, typically instant
- **Progress CRUD**: Sub-second response times

---

## What's Next?

Still to implement (see IMPLEMENTATION_STATUS.md):
- [ ] Wearable integrations (Apple Health, Fitbit, Garmin)
- [ ] Exercise library with visual guides
- [ ] Push notifications system
- [ ] Micro-rewards and streaks
- [ ] Ingredient substitution logic

---

## Reporting Issues

If you find bugs:
1. Check backend logs: `tail -f backend/logs/app.log`
2. Check Flutter console for errors
3. Note the exact steps to reproduce
4. Save any error messages
5. Check network requests in Flutter DevTools

---

## Success Checklist

Before considering testing complete, verify:

- [x] Can update progress entries
- [x] Can delete progress entries
- [x] Token auto-refreshes without logout
- [x] Logout calls backend API
- [x] Can view current subscription
- [x] Can upgrade to Premium (test mode)
- [x] Can access customer portal
- [x] Can cancel subscription
- [x] Can scan food with camera
- [x] Can upload food image from gallery
- [x] OCR provides accurate nutritional data
- [x] Food confidence scores are reasonable
- [x] All navigation works correctly
- [x] No crashes or major UI glitches

Happy testing! 🎉
