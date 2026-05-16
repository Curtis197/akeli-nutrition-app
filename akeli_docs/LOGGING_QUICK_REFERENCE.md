# Akeli Logging Quick Reference

## 🚀 Quick Start

### 1. Import the Logger
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

### 2. Use Category-Specific Methods
```dart
_logger.auth('Sign-in successful for userId: ${user.id}');
_logger.db('Fetching recipes for userId: $userId');
_logger.rls('Permission denied on recipe query');
_logger.provider('RecipeFeedNotifier refresh triggered');
_logger.edge('toggle-recipe-like', 'Function invoked');
_logger.userAction('Like button tapped', screen: 'RecipeDetail');
```

---

## 📋 Logging Checklist

### ✅ For Every New Feature

#### Flutter (Dart)
- [ ] Import logger: `import 'package:akeli/core/logger.dart';`
- [ ] Create logger instance: `final _logger = appLogger;`
- [ ] Log entry point (function/provider initialization)
- [ ] Log main operation (query, mutation, auth call)
- [ ] Log result (success with count, or error with details)
- [ ] Add RLS check if querying Supabase
- [ ] Wrap in try/catch and log errors with stack traces
- [ ] Test happy path → verify logs appear
- [ ] Test error paths → verify errors are logged

#### Edge Functions (TypeScript)
- [ ] Import logger: `import { createLogger } from '../_shared/logger.ts';`
- [ ] Create logger: `const logger = createLogger('function-name');`
- [ ] Generate requestId: `const requestId = crypto.randomUUID();`
- [ ] Log invocation with requestId
- [ ] Log auth verification (userId)
- [ ] Log database operations
- [ ] Log external API calls
- [ ] Log response (success/error)
- [ ] Add catch-all error handler

---

## 🎯 Common Patterns

### Pattern 1: Auth Flow
```dart
Future<User?> signIn(String email, String password) async {
  final maskedEmail = LogHelper.maskEmail(email);
  _logger.auth('Sign-in attempt for email: $maskedEmail');
  
  try {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    _logger.auth('Sign-in successful for userId: ${response.user?.id}');
    return response.user;
  } on AuthException catch (e, st) {
    _logger.auth('Sign-in failed: ${e.message}', error: e, stackTrace: st);
    rethrow;
  }
}
```

### Pattern 2: Database Query with RLS
```dart
Future<List<Recipe>> fetchRecipes(String userId) async {
  _logger.db('Fetching recipes for userId: $userId');
  
  RLSDebugHelper.debugQuery('recipe', userId);
  
  try {
    final response = await supabase
        .from('recipe')
        .select()
        .eq('is_published', true)
        .limit(20);
    
    if (response.isEmpty) {
      _logger.rls('Recipe query returned 0 rows. Possible RLS block.');
    } else {
      _logger.db('Retrieved ${response.length} recipes');
    }
    
    return response.map((json) => Recipe.fromJson(json)).toList();
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls('Permission denied on recipe query', error: e, stackTrace: st);
    } else {
      _logger.db('Query failed: ${e.message}', error: e, stackTrace: st);
    }
    rethrow;
  }
}
```

### Pattern 3: Riverpod Provider
```dart
class MyNotifier extends AsyncNotifier<List<Item>> {
  final _logger = appLogger;

  @override
  Future<List<Item>> build() async {
    _logger.provider('MyNotifier initialized');
    
    ref.onDispose(() {
      _logger.provider('MyNotifier disposed');
    });
    
    return _fetchItems();
  }

  Future<void> refresh() async {
    _logger.provider('MyNotifier refresh triggered');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final items = await _fetchItems();
      _logger.provider('MyNotifier refresh successful');
      return items;
    });
  }
}
```

### Pattern 4: Edge Function
```typescript
serve(async (req: Request) => {
  const logger = createLogger('my-function');
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  
  logger.info('Function invoked');
  
  try {
    const supabase = userClient(req);
    const { user } = await supabase.auth.getUser();
    logger.setUserId(user.id);
    logger.info('User authenticated');
    
    // Do work...
    logger.info('Function completed successfully');
    
    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error) {
    logger.error('Unhandled error', { error: error.message });
    return new Response(JSON.stringify({ error: 'Internal error' }), { status: 500 });
  }
});
```

---

## 🔍 RLS Debugging

### When to Suspect RLS Issues
- Query returns empty array but you expect data
- Insert/update/delete affects 0 rows unexpectedly
- No error message, just "missing" data

### How to Debug RLS
```dart
// 1. Use RLSDebugHelper
RLSDebugHelper.debugQuery('recipe', userId, filters: {'is_published': true});

// 2. Check logs for RLS warnings
// Look for: ⚠️ RLS: Recipe query returned 0 rows...

// 3. Manually check policies in Supabase dashboard
// Go to: Authentication → Policies → recipe table

// 4. Test with service role key (bypasses RLS)
// Only for debugging, never in production!
```

### Common RLS Policy Patterns
```sql
-- Users can view their own data
CREATE POLICY "Users can view own profile"
ON user_profile FOR SELECT
USING (auth.uid() = id);

-- Users can view published content
CREATE POLICY "Anyone can view published recipes"
ON recipe FOR SELECT
USING (is_published = true);

-- Users can insert their own data
CREATE POLICY "Users can insert own recipes"
ON recipe FOR INSERT
WITH CHECK (auth.uid() = creator_id);
```

---

## 🚨 Never Log These

❌ **Passwords or password hashes**
❌ **Full JWT tokens** (log only userId or first/last 4 chars)
❌ **Payment card numbers**
❌ **Personal identifiable information (PII)** without hashing
❌ **API keys or service role keys**
❌ **Refresh tokens**
❌ **Credit card CVV**

---

## ✅ Always Log These

✅ **User IDs** (UUIDs, not emails)
✅ **Timestamps**
✅ **Request IDs** for correlation
✅ **Error types and messages** (not stack traces in production)
✅ **Operation success/failure**
✅ **RLS policy checks**
✅ **Provider lifecycle events**

---

## 📊 Log Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| `trace` | Every state change, variable values | Provider state transitions |
| `debug` | Developer debugging, query details | SQL queries, filters |
| `info` | Important events | Auth success, user actions |
| `warning` | Potential issues | RLS blocks, deprecated API |
| `error` | Actual errors | Exceptions, failed operations |

---

## 🎨 Emoji Legend

| Emoji | Method | Meaning |
|-------|--------|---------|
| 🔐 | `_logger.auth()` | Authentication events |
| 📡 | `_logger.db()` | Database operations |
| 🔍 | `_logger.rls()` | RLS checks |
| 🔄 | `_logger.provider()` | Provider lifecycle |
| ⚡ | `_logger.edge()` | Edge functions |
| 🎯 | `_logger.userAction()` | User actions |
| ✅ | Success | Operation completed |
| ❌ | Error | Operation failed |
| ⚠️ | Warning | Potential issue |
| 🚫 | Blocked | RLS policy blocked |
| 💥 | Critical | Unhandled exception |

---

## 📁 File Structure

```
lib/
├── core/
│   └── logger.dart                    # Main logger utility
└── providers/
    ├── _examples/
    │   ├── auth_provider_logged.dart  # Auth example with logs
    │   └── recipe_provider_logged.dart # Data example with logs
    ├── auth_provider.dart             # Your auth provider (add logs!)
    └── recipe_provider.dart           # Your recipe provider (add logs!)

supabase/
└── functions/
    ├── _shared/
    │   └── logger.ts                  # Edge function logger
    └── _examples/
        └── complete-onboarding-logged.ts # Edge function example
```

---

## 🔗 References

- **Full Instructions**: `LOGGING_INSTRUCTIONS.md`
- **Logging Skill**: `.qwen/skills/logging.md`
- **Flutter Logger Package**: https://pub.dev/packages/logger
- **Supabase RLS**: https://supabase.com/docs/guides/auth/row-level-security
- **Riverpod Lifecycle**: https://riverpod.dev/docs/concepts/provider_lifecycle

---

**Version**: 1.0.0  
**Created**: 2026-04-13
