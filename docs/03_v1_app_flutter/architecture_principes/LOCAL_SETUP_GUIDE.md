# 🚀 Akeli Local Development Setup Guide

**Last Updated:** 2026-05-20  
**Status:** ✅ Ready for Local Testing

---

## Quick Start

### Prerequisites
- [ ] Flutter SDK (3.19+)
- [ ] Supabase CLI (`npm install -g supabase`)
- [ ] Docker Desktop (for local Supabase)
- [ ] Android Studio / Xcode (for emulators)

---

## Step 1: Environment Configuration

### 1.1 Copy Environment File
```bash
cp .env.example .env
```

### 1.2 Update `.env` with Local Credentials
```env
# Local Supabase Configuration
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0

# API Keys (Mock for local)
OPENAI_API_KEY=sk-local-mock-key
STRIPE_SECRET_KEY=sk_test_mock_key
STRIPE_PUBLISHABLE_KEY=pk_test_mock_key

# App Configuration
APP_ENV=local
LOG_LEVEL=debug
ENABLE_MOCK_DATA=false
```

---

## Step 2: Start Local Supabase

### 2.1 Initialize Supabase Project
```bash
cd /workspace
supabase init
```

### 2.2 Start Local Supabase Stack
```bash
supabase start
```

This will:
- Start PostgreSQL database on port 54322
- Start GoTrue (auth) on port 9999
- Start PostgREST (API) on port 54321
- Start Storage API on port 54323
- Start Studio on http://localhost:54323

### 2.3 Apply Database Migrations
```bash
supabase db reset  # Fresh start with all migrations
# OR
supabase migration up  # Apply migrations incrementally
```

**Available Migrations:**
1. `20260301000001_initial_schema.sql` - Core tables (users, recipes, meals)
2. `20260301000002_rpc_functions.sql` - Database functions
3. `20260302000001_store_payment_arch.sql` - Payment architecture
4. `20260302000002_fix_rls_policies.sql` - RLS policy fixes
5. `20260302000003_add_recipe_steps.sql` - Recipe steps table
6. `20260314000001_recipe_tracking_schema.sql` - Recipe tracking
7. `20260413000001_annotate_all_tables.sql` - Annotations system
8. `20260516000001_modular_meal_batch_cooking.sql` - Meal planning v2
9. `20260517000001_fix_recipe_step_rls.sql` - RLS fix for steps
10. `20260517000002_subscription_insert_guard.sql` - Subscription guard
11. `20260517000003_recommendation_feed_engine.sql` - Feed recommendations

### 2.4 Deploy Edge Functions
```bash
supabase functions deploy activate-fan-mode
supabase functions deploy ai-assistant-chat
supabase functions deploy cancel-fan-mode
supabase functions deploy complete-onboarding
supabase functions deploy compute-monthly-revenue
supabase functions deploy create-checkout-session
supabase functions deploy generate-meal-plan
supabase functions deploy get-creator-dashboard
supabase functions deploy log-meal-consumption
supabase functions deploy process-fan-mode-transitions
supabase functions deploy send-meal-reminders
supabase functions deploy send-push-notification
supabase functions deploy stripe-webhook
supabase functions deploy toggle-recipe-like
```

Or deploy all at once:
```bash
for fn in supabase/functions/*/; do
  fn_name=$(basename $fn)
  if [[ ! $fn_name == _* ]]; then
    supabase functions deploy $fn_name
  fi
done
```

### 2.5 Access Supabase Studio
Open http://localhost:54323 in your browser to:
- View database tables
- Manage authentication users
- Test edge functions
- Monitor logs

---

## Step 3: Platform Configuration

### 3.1 Android Configuration ✅ COMPLETED
File: `android/app/build.gradle.kts`
```kotlin
namespace = "com.akeli.nutrition"
applicationId = "com.akeli.nutrition"
minSdk = 23
versionCode = 1
versionName = "1.0.0-local"
```

### 3.2 iOS Configuration ⚠️ MANUAL STEP
File: `ios/README.md` (created)

**To regenerate iOS folder:**
```bash
flutter create --platforms=ios --org=com.akeli --project-name=akeli . --overwrite
```

**Manual setup:**
1. Update Bundle ID to `com.akeli.nutrition`
2. Configure signing in Xcode
3. Add capabilities: Camera, Photo Library, Notifications

---

## Step 4: Routing Configuration ✅ COMPLETED

All new pages have been added to `lib/core/router.dart`:

| Route | Path | Page |
|-------|------|------|
| `support` | `/support` | SupportPage |
| `privacyPolicy` | `/privacy-policy` | PrivacyPolicyPage |
| `termsOfService` | `/terms-of-service` | TermsOfServicePage |
| `referral` | `/referral` | ReferralPage |

**Total routes:** 24 (including nested routes)

---

## Step 5: Run the App

### 5.1 Get Dependencies
```bash
flutter pub get
```

### 5.2 Run on Android Emulator
```bash
flutter run -d android
```

### 5.3 Run on iOS Simulator (if iOS folder exists)
```bash
flutter run -d ios
```

### 5.4 Run on Chrome (for quick UI testing)
```bash
flutter run -d chrome
```

---

## Step 6: Testing Checklist

### Authentication Flow
- [ ] Sign up with email/password
- [ ] Email verification (mocked locally)
- [ ] Login with existing account
- [ ] Password reset flow
- [ ] Onboarding completion

### Core Features
- [ ] Home dashboard loads
- [ ] Recipe feed displays
- [ ] Recipe detail view
- [ ] Meal planner (day rows + meal cards dynamic)
- [ ] Shopping list generation
- [ ] Nutrition tracking
- [ ] AI chat assistant

### New Pages
- [ ] Support page form submission
- [ ] Privacy Policy display
- [ ] Terms of Service display
- [ ] Referral code management

### Logging Verification
Check that logs appear in console:
```
🧭 [Navigation] /home → /recipes | reason: user action
📝 [UserAction] recipe_viewed | recipe_id: xxx
✅ [Success] Data loaded successfully
```

---

## Troubleshooting

### Issue: Supabase won't start
```bash
supabase stop
docker system prune -a
supabase start
```

### Issue: Migration errors
```bash
supabase db reset  # Warning: Deletes all data
```

### Issue: Edge function deployment fails
```bash
# Check function logs
supabase functions logs <function-name>

# Redeploy with verbose output
supabase functions deploy <function-name> --verbose
```

### Issue: Flutter build fails
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Hot reload not working
```bash
# Full restart
Press 'R' in terminal for hot restart
# Or
Press 'r' for hot reload
```

---

## Next Steps After Local Testing

1. **Fix Bugs**: Address any issues found during testing
2. **Integration Tests**: Add widget tests and integration tests
3. **Production Supabase**: Set up production Supabase project
4. **Update Environment**: Create `.env.production` with real credentials
5. **Build Release**: 
   ```bash
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```
6. **Store Submission**: Prepare for Google Play / App Store

---

## Useful Commands

### Supabase
```bash
supabase status          # Check local stack status
supabase stop            # Stop local stack
supabase db diff         # Generate migration from schema changes
supabase gen types dart  # Generate Dart types from database
```

### Flutter
```bash
flutter analyze          # Static analysis
flutter test             # Run tests
flutter doctor           # Check development environment
flutter pub outdated     # Check for dependency updates
```

---

## Support

For issues or questions:
- Check `/docs/` directory for detailed documentation
- Review `/audit/` reports for known issues
- Consult Stitch designs in `/stitch/` for UI reference

