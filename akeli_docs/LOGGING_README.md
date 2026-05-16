# 📝 Akeli Nutrition App - Logging System

## 🚨 CORE PRINCIPLE: LOG EVERYTHING, GUESS NOTHING

**Every single action, event, state change, user interaction, network call, database query, provider lifecycle, navigation, error, exception, and UI update MUST be logged extensively.**

We do NOT guess where bugs come from. We KNOW exactly where because EVERYTHING is logged.

---

## Overview

Comprehensive **AGGRESSIVE** logging infrastructure has been implemented for the Akeli Nutrition App. This means:

- ✅ **EVERY function** logs entry, decisions, and exit
- ✅ **EVERY conditional** logs which branch was taken and WHY
- ✅ **EVERY state change** logs old state, new state, and trigger
- ✅ **EVERY user action** logs what happened with full context
- ✅ **EVERY database query** logs BEFORE, AFTER, and RLS checks
- ✅ **EVERY navigation** logs from, to, trigger, and redirect decisions
- ✅ **EVERY error** is logged with stack trace and context
- ✅ **EVERY widget build** logs what was rendered and WHY

---

## 📁 What Was Created

### Documentation
1. **`LOGGING_INSTRUCTIONS.md`** - Comprehensive logging guidelines (the "bible")
2. **`LOGGING_QUICK_REFERENCE.md`** - Quick reference for daily use
3. **`.qwen/skills/logging.md`** - Qwen Code skill for automatic logging

### Flutter (Dart) Code
4. **`lib/core/logger.dart`** - Centralized logger with helper utilities
5. **`lib/providers/_examples/auth_provider_logged.dart`** - Auth provider example
6. **`lib/providers/_examples/recipe_provider_logged.dart`** - Data provider example

### Supabase Edge Functions (TypeScript)
7. **`supabase/functions/_shared/logger.ts`** - Edge function logger
8. **`supabase/functions/_examples/complete-onboarding-logged.ts`** - Complete example

---

## 🚀 How to Use

### For Developers

#### 1. Read the Guidelines
Start with `LOGGING_INSTRUCTIONS.md` to understand the logging philosophy and standards.

#### 2. Use the Logger in Your Code
```dart
import 'package:akeli/core/logger.dart';

class MyProvider extends AsyncNotifier<List<Item>> {
  final _logger = appLogger;

  @override
  Future<List<Item>> build() async {
    _logger.provider('MyProvider initialized');
    return _fetchItems();
  }
}
```

#### 3. Check the Examples
Look at the `_examples/` folders to see complete implementations with logging.

#### 4. Use the Quick Reference
Keep `LOGGING_QUICK_REFERENCE.md` open for copy-paste patterns.

---

### For Qwen Code (AI Assistant)

When the user asks to:
- "add logging"
- "implement logging"
- "log this feature"
- or invokes `/skill logging`

The AI will automatically follow the logging skill instructions in `.qwen/skills/logging.md` to add comprehensive logging to any code it writes or modifies.

---

## 📋 Implementation Checklist

### Phase 1: Critical (Do This First)
- [ ] Add auth provider logging (sign-in, sign-up, sign-out)
- [ ] Add Supabase query logging (all fetches, inserts, updates)
- [ ] Add RLS violation detection logging
- [ ] Add edge function invocation logging

### Phase 2: Important (Do This Next)
- [ ] Add Riverpod provider lifecycle logging
- [ ] Add navigation/routing logging
- [ ] Add user action logging
- [ ] Add error boundary logging (try/catch everywhere)

### Phase 3: Nice to Have (Do This Later)
- [ ] Add performance timing (query duration)
- [ ] Add analytics events (screen views, user flows)
- [ ] Add remote logging (send errors to Supabase logs table)
- [ ] Add log filtering by category

---

## 🎯 Key Features

### 1. Category-Specific Logging
```dart
_logger.auth('Sign-in successful');      // 🔐 Authentication
_logger.db('Fetching recipes');           // 📡 Database
_logger.rls('Permission denied');         // 🔍 RLS check
_logger.provider('Provider initialized'); // 🔄 Provider lifecycle
_logger.userAction('Button tapped');      // 🎯 User action
```

### 2. RLS Debug Helper
```dart
RLSDebugHelper.debugQuery('recipe', userId, filters: {'is_published': true});
// Automatically logs warnings if query returns 0 rows unexpectedly
```

### 3. Security Helpers
```dart
LogHelper.maskEmail('john@example.com');  // "joh***@exa***"
LogHelper.maskUuid('abc123-def456');      // "abc1***f456"
LogHelper.sanitizeData({email, password}); // Removes password field
```

### 4. Request Correlation (Edge Functions)
```typescript
const requestId = crypto.randomUUID();
logger.setRequestId(requestId);
logger.setUserId(userId);
// All subsequent logs include requestId and userId for debugging
```

---

## 🔍 Debugging RLS Issues

### The Problem
RLS policies can **silently block queries** without throwing errors. You get an empty array instead of data, which looks like "no data exists" when it's actually "you don't have permission".

### The Solution
Our logger automatically detects and warns about potential RLS blocks:

```dart
if (response.isEmpty && offset == 0) {
  _logger.rls('Recipe query returned 0 rows. Possible RLS policy blocking.');
  _logger.rls('Check RLS policies on "recipe" table for auth_uid() match');
}
```

### The Logs Will Show
```
⚠️ RLS: Recipe query returned 0 rows for offset 0. Possible RLS policy blocking.
⚠️ RLS: Check RLS policies on "recipe" table for auth_uid() match or creator visibility
```

---

## 📊 Log Output Example

```
┌──────────────────────────────────────────────
│ 🕐 14:32:15.123 
│ 📍 auth_provider.dart:78 <signIn>
│
│ 🔐 Auth: Sign-in attempt for email: joh***@exa***
└──────────────────────────────────────────────

┌──────────────────────────────────────────────
│ 🕐 14:32:16.456 
│ 📍 auth_provider.dart:85 <signIn>
│
│ ✅ Auth: Sign-in successful for userId: abc1***f456
└──────────────────────────────────────────────

┌──────────────────────────────────────────────
│ 🕐 14:32:17.789 
│ 📍 recipe_provider.dart:34 <build>
│
│ 📡 DB: Fetching recipes for userId: abc1***f456, filters: {limit: 20}
└──────────────────────────────────────────────

┌──────────────────────────────────────────────
│ 🕐 14:32:18.012 
│ 📍 recipe_provider.dart:42 <build>
│
│ ⚠️ RLS: Recipe query returned 0 rows. Possible RLS policy blocking.
│ ⚠️ RLS: Check policies on "recipe" table for auth_uid() match
└──────────────────────────────────────────────
```

---

## 🚨 Common Bugs Caught by Logging

### Auth Bugs
- ❌ User appears logged in but token is expired
- ❌ Sign-up succeeds but profile isn't created
- ❌ Token refresh fails silently → user logged out unexpectedly

### RLS Bugs
- ❌ Query returns empty array → actually RLS blocking, not no data
- ❌ Insert fails → RLS policy doesn't allow INSERT for this role
- ❌ Update affects 0 rows → policy check uses wrong column

### State Management Bugs
- ❌ Provider rebuilds unnecessarily → performance issue
- ❌ Provider doesn't update → missing `ref.notifyListeners()`
- ❌ Stale data → provider not invalidated after mutation

### Network Bugs
- ❌ Timeout on slow connection → no retry logic
- ❌ CORS errors in web → Supabase URL misconfigured
- ❌ Rate limiting → too many requests without caching

---

## 🔒 Security

### What We NEVER Log
- ❌ Passwords or password hashes
- ❌ Full JWT tokens (only userId or first/last 4 chars)
- ❌ Payment card numbers
- ❌ Personal identifiable information (PII) without hashing
- ❌ API keys or service role keys
- ❌ Refresh tokens

### What We ALWAYS Log
- ✅ User IDs (UUIDs, masked)
- ✅ Timestamps
- ✅ Request IDs for correlation
- ✅ Error types and messages (not full stack traces in production)
- ✅ Operation success/failure
- ✅ RLS policy checks

---

## 📚 Next Steps

### 1. Integrate Supabase Client
The main app currently uses mock data. When you wire up Supabase:
- Replace mock providers with real Supabase calls
- Add logging to all queries and mutations
- Test RLS policies with the debug logger

### 2. Add Remote Logging (Optional)
Create a Supabase table for critical errors:
```sql
CREATE TABLE error_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level TEXT NOT NULL,
  category TEXT NOT NULL,
  message TEXT NOT NULL,
  user_id UUID,
  request_id UUID,
  stack_trace TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

Then send critical errors to this table in production.

### 3. Set Up Log Monitoring
Use Supabase logs or external services (Sentry, LogRocket) for:
- Real-time error alerts
- Performance monitoring
- User behavior analytics

---

## 🤝 Contributing

When adding new features:

1. **Read the logging skill** (`.qwen/skills/logging.md`)
2. **Follow the patterns** in `_examples/` folders
3. **Use the checklist** in `LOGGING_QUICK_REFERENCE.md`
4. **Test your logs** by running happy and error paths

---

## 📞 Support

- **Full Instructions**: `LOGGING_INSTRUCTIONS.md`
- **Quick Reference**: `LOGGING_QUICK_REFERENCE.md`
- **Logging Skill**: `.qwen/skills/logging.md`
- **Flutter Logger**: https://pub.dev/packages/logger
- **Supabase RLS**: https://supabase.com/docs/guides/auth/row-level-security

---

**Version**: 1.0.0  
**Created**: 2026-04-13  
**Last Updated**: 2026-04-13  
**Maintainer**: Akeli Dev Team
