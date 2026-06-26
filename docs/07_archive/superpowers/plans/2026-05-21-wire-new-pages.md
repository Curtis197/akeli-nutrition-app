# Wire New Pages — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the 6 new pages on `fix-compliance-and-router-issues-814be` fully testable and deployable by wiring real Supabase data, fixing navigation, adding two missing DB migrations, and converting stub pages to live implementations.

**Architecture:** Each page becomes a `ConsumerStatefulWidget` reading from `currentUserProvider` and `supabaseClientProvider` (already used across the app). Two SQL migrations add the missing `referral_code` column and `journal_entry` table. Navigation uses `context.pop()` from `go_router`.

**Tech Stack:** Flutter, Riverpod, Supabase Flutter, GoRouter, image_picker (already in pubspec)

---

## File Map

| File | Action |
|---|---|
| `supabase/migrations/20260521000001_add_referral_code_to_user_profile.sql` | Create |
| `supabase/migrations/20260521000002_create_journal_entry.sql` | Create |
| `lib/features/support/support_page.dart` | Modify — ConsumerStatefulWidget, real insert |
| `lib/features/referral/referral_page.dart` | Modify — ConsumerStatefulWidget, load/save from DB |
| `lib/features/journaling/journaling_bottom_sheet.dart` | Modify — ConsumerStatefulWidget, real insert, image picker |
| `lib/features/legal/privacy_policy_page.dart` | Modify — Navigator.pop → context.pop |
| `lib/features/legal/terms_of_service_page.dart` | Modify — Navigator.pop → context.pop |

`cooking_session_bottom_sheet.dart` is an intentional "coming soon" placeholder — no changes needed.

---

## Task 1 — Fix Navigator.pop → context.pop() across 4 pages

**Files:** `support_page.dart`, `privacy_policy_page.dart`, `terms_of_service_page.dart`, `referral_page.dart`

`Navigator.pop` bypasses GoRouter's route lifecycle on top-level `GoRoute` entries. `context.pop()` is provided by the `go_router` package via `BuildContext` extension.

- [ ] Add `go_router` import to `support_page.dart`, `privacy_policy_page.dart`, `terms_of_service_page.dart`, `referral_page.dart`:

```dart
import 'package:go_router/go_router.dart';
```

- [ ] In `support_page.dart` replace both `Navigator.pop(context)` calls:

```dart
// AppBar back button (line ~101):
onPressed: () => context.pop(),

// After successful submit (line ~71):
context.pop();
```

- [ ] In `privacy_policy_page.dart` replace `Navigator.pop(context)`:

```dart
onPressed: () {
  _logger.userAction('Back tapped', screen: 'PrivacyPolicyPage');
  context.pop();
},
```

- [ ] In `terms_of_service_page.dart` replace `Navigator.pop(context)`:

```dart
onPressed: () {
  _logger.userAction('Back tapped', screen: 'TermsOfServicePage');
  context.pop();
},
```

- [ ] In `referral_page.dart` replace `Navigator.pop(context)`:

```dart
onPressed: () => context.pop(),
```

- [ ] Commit:

```bash
git add lib/features/support/support_page.dart \
        lib/features/legal/privacy_policy_page.dart \
        lib/features/legal/terms_of_service_page.dart \
        lib/features/referral/referral_page.dart
git commit -m "fix: replace Navigator.pop with context.pop() on all GoRouter pages"
```

---

## Task 2 — Migration: add referral_code to user_profile

The `referral` table records WHO referred WHOM and WHAT code was used. It does not store a user's own shareable code. `user_profile` needs a `referral_code` column so each user has one stable personal code.

- [ ] Create `supabase/migrations/20260521000001_add_referral_code_to_user_profile.sql`:

```sql
-- Add personal referral code to user_profile
-- Each user gets a unique shareable code, defaulting to 'AKELI-' + first 6 chars of their UUID

ALTER TABLE user_profile
  ADD COLUMN IF NOT EXISTS referral_code text UNIQUE;

-- Back-fill existing rows
UPDATE user_profile
SET referral_code = 'AKELI-' || UPPER(SUBSTRING(id::text, 1, 6))
WHERE referral_code IS NULL;

-- Add NOT NULL after back-fill
ALTER TABLE user_profile
  ALTER COLUMN referral_code SET DEFAULT 'AKELI-' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 6));

-- Index for quick code lookups at sign-up
CREATE INDEX IF NOT EXISTS idx_user_profile_referral_code ON user_profile(referral_code);

-- RLS: anyone can look up a code (needed for sign-up validation)
CREATE POLICY "public reads referral_code" ON user_profile
  FOR SELECT USING (true);
```

> Note: The "public reads" policy on `user_profile` already exists in the initial schema (`public reads minimal profile`). If it conflicts on push, drop the new policy line — the existing one covers it.

- [ ] Commit:

```bash
git add supabase/migrations/20260521000001_add_referral_code_to_user_profile.sql
git commit -m "feat(db): add referral_code column to user_profile with default and index"
```

---

## Task 3 — Migration: create journal_entry table

- [ ] Create `supabase/migrations/20260521000002_create_journal_entry.sql`:

```sql
-- Journal entries — daily food diary with optional photo attachments

CREATE TABLE journal_entry (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES user_profile(id) ON DELETE CASCADE,
  meal_type   text NOT NULL CHECK (meal_type IN ('Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation')),
  description text NOT NULL,
  photo_urls  text[] DEFAULT '{}',
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX idx_journal_entry_user ON journal_entry(user_id, created_at DESC);

ALTER TABLE journal_entry ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner only journal_entry" ON journal_entry
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

- [ ] Commit:

```bash
git add supabase/migrations/20260521000002_create_journal_entry.sql
git commit -m "feat(db): create journal_entry table with RLS"
```

---

## Task 4 — Wire support_page: ConsumerStatefulWidget + real Supabase insert

**File:** `lib/features/support/support_page.dart`

- [ ] Replace class declarations (widget + state) at the top of the file:

```dart
class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key});

  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<SupportPage> {
```

- [ ] Add missing imports at the top of the file (after existing imports):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import '../../providers/auth_provider.dart';
```

- [ ] In `initState`, pre-fill email from the authenticated user:

```dart
@override
void initState() {
  super.initState();
  _logger.provider('SupportPage build()');
  final user = ref.read(currentUserProvider);
  if (user?.email != null) {
    _emailController.text = user!.email!;
  }
}
```

- [ ] Replace the entire `_submitForm` method body with a real Supabase insert:

```dart
Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) {
    _logger.provider('SupportPage | form validation failed');
    return;
  }

  _logger.userAction('Submit support ticket tapped', screen: 'SupportPage');
  setState(() => _isSubmitting = true);

  final user = ref.read(currentUserProvider);
  final client = ref.read(supabaseClientProvider);

  try {
    _logger.db('BEFORE | table: support_message | op: INSERT | userId: ${user?.id}');
    await client.from('support_message').insert({
      'user_id': user?.id,
      'email': _emailController.text.trim(),
      'subject': _nameController.text.trim(),
      'content': _messageController.text.trim(),
    });
    _logger.db('AFTER | table: support_message | rows: 1');
    _logger.provider('SupportPage | ticket submitted');

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Message envoyé avec succès!'),
          backgroundColor: AkeliColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
          ),
        ),
      );
      context.pop();
    }
  } on PostgrestException catch (e, st) {
    _logger.db('ERROR | table: support_message | code: ${e.code}', error: e, stackTrace: st);
    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de l\'envoi. Veuillez réessayer.'),
          backgroundColor: AkeliColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
          ),
        ),
      );
    }
  } catch (e, st) {
    _logger.db('ERROR | table: support_message | unexpected | $e', error: e, stackTrace: st);
    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de l\'envoi. Veuillez réessayer.'),
          backgroundColor: AkeliColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
          ),
        ),
      );
    }
  }
}
```

- [ ] Verify: `flutter analyze lib/features/support/support_page.dart` — 0 errors.

- [ ] Manual test: navigate to `/support`, verify email is pre-filled, submit a ticket, check Supabase dashboard → `support_message` table has a new row.

- [ ] Commit:

```bash
git add lib/features/support/support_page.dart
git commit -m "feat: wire support_page to support_message table with real Supabase insert"
```

---

## Task 5 — Wire referral_page: load code + count from DB, save code

**File:** `lib/features/referral/referral_page.dart`

- [ ] Add missing imports:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import '../../providers/auth_provider.dart';
```

- [ ] Replace both class declarations:

```dart
class ReferralPage extends ConsumerStatefulWidget {
  const ReferralPage({super.key});

  @override
  ConsumerState<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends ConsumerState<ReferralPage> {
```

- [ ] Replace all state fields and add `_isLoading`:

```dart
  final _logger = appLogger;
  final _codeController = TextEditingController();
  int _referralCount = 0;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoading = true;
```

- [ ] Add `_loadData()` and update `initState`:

```dart
@override
void initState() {
  super.initState();
  _logger.provider('ReferralPage build()');
  _loadData();
}

Future<void> _loadData() async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;
  final client = ref.read(supabaseClientProvider);

  try {
    _logger.db('BEFORE | table: user_profile | op: SELECT referral_code | userId: ${user.id}');
    final profile = await client
        .from('user_profile')
        .select('referral_code')
        .eq('id', user.id)
        .maybeSingle();
    _logger.db('AFTER | table: user_profile | rows: ${profile == null ? 0 : 1}');

    _logger.db('BEFORE | table: referral | op: COUNT | referrerId: ${user.id}');
    final referrals = await client
        .from('referral')
        .select('id')
        .eq('referrer_id', user.id);
    _logger.db('AFTER | table: referral | rows: ${referrals.length}');

    if (mounted) {
      setState(() {
        _codeController.text = (profile?['referral_code'] as String?) ??
            'AKELI-${user.id.substring(0, 6).toUpperCase()}';
        _referralCount = referrals.length;
        _isLoading = false;
      });
    }
  } on PostgrestException catch (e, st) {
    _logger.db('ERROR | table: user_profile/referral | ${e.code}', error: e, stackTrace: st);
    if (mounted) setState(() => _isLoading = false);
  } catch (e, st) {
    _logger.db('ERROR | _loadData | unexpected | $e', error: e, stackTrace: st);
    if (mounted) setState(() => _isLoading = false);
  }
}
```

- [ ] Replace `_saveCode()` with a real upsert:

```dart
Future<void> _saveCode() async {
  _logger.userAction('Save referral code tapped', screen: 'ReferralPage');
  final user = ref.read(currentUserProvider);
  if (user == null) return;
  final client = ref.read(supabaseClientProvider);

  setState(() => _isSaving = true);
  try {
    _logger.db('BEFORE | table: user_profile | op: UPDATE referral_code | userId: ${user.id}');
    await client
        .from('user_profile')
        .update({'referral_code': _codeController.text.trim().toUpperCase()})
        .eq('id', user.id);
    _logger.db('AFTER | table: user_profile | referral_code updated');

    if (mounted) {
      setState(() { _isSaving = false; _isEditing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code mis à jour avec succès!'),
          backgroundColor: AkeliColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
          ),
        ),
      );
    }
  } on PostgrestException catch (e, st) {
    _logger.db('ERROR | table: user_profile | code: ${e.code}', error: e, stackTrace: st);
    if (mounted) setState(() => _isSaving = false);
  } catch (e, st) {
    _logger.db('ERROR | _saveCode | $e', error: e, stackTrace: st);
    if (mounted) setState(() => _isSaving = false);
  }
}
```

- [ ] Fix the hero code display bug — replace the hardcoded text with the controller value, and show a loading state:

```dart
// Replace the build() return with a loading guard at the top of build():
@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return Scaffold(
      backgroundColor: AkeliColors.surface,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
  return Scaffold(
    // ... rest unchanged except the two fixes below
```

- [ ] Fix the hero display text — replace the hardcoded `'AKELI-SOFI'` literal:

```dart
// Replace:
_isEditing ? '' : 'AKELI-SOFI',

// With:
_codeController.text,
```

- [ ] Verify: `flutter analyze lib/features/referral/referral_page.dart` — 0 errors.

- [ ] Manual test: open `/referral`, verify it shows YOUR code (not AKELI-SOFI), referral count matches DB, editing and saving updates the `user_profile.referral_code` column in Supabase dashboard.

- [ ] Commit:

```bash
git add lib/features/referral/referral_page.dart
git commit -m "feat: wire referral_page to DB — load code + count, save code to user_profile"
```

---

## Task 6 — Wire journaling_bottom_sheet: ConsumerStatefulWidget + insert + image picker

**File:** `lib/features/journaling/journaling_bottom_sheet.dart`

- [ ] Add missing imports:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import '../../providers/auth_provider.dart';
```

- [ ] Replace both class declarations:

```dart
class JournalingBottomSheet extends ConsumerStatefulWidget {
  const JournalingBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    appLogger.userAction('Journaling sheet opened', screen: 'JournalingBottomSheet');
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JournalingBottomSheet(),
    );
  }

  @override
  ConsumerState<JournalingBottomSheet> createState() => _JournalingBottomSheetState();
}

class _JournalingBottomSheetState extends ConsumerState<JournalingBottomSheet> {
```

- [ ] Replace state fields to use `XFile` instead of `String`:

```dart
  final _logger = appLogger;
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  String _selectedMealType = 'Déjeuner';
  bool _isSaving = false;
  List<XFile> _selectedImages = [];

  final List<String> _mealTypes = ['Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation'];
```

- [ ] Replace `_saveEntry()` with a real Supabase insert:

```dart
Future<void> _saveEntry() async {
  if (_descriptionController.text.isEmpty) {
    _logger.provider('JournalingBottomSheet | save blocked | empty description');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Veuillez ajouter une description'),
        backgroundColor: AkeliColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkeliRadius.lg),
        ),
      ),
    );
    return;
  }

  _logger.userAction('Save journal entry tapped', screen: 'JournalingBottomSheet');
  setState(() => _isSaving = true);

  final user = ref.read(currentUserProvider);
  final client = ref.read(supabaseClientProvider);

  try {
    _logger.db('BEFORE | table: journal_entry | op: INSERT | userId: ${user?.id}');
    await client.from('journal_entry').insert({
      'user_id': user?.id,
      'meal_type': _selectedMealType,
      'description': _descriptionController.text.trim(),
      'photo_urls': <String>[],   // Storage upload is a future task
    });
    _logger.db('AFTER | table: journal_entry | rows: 1');
    _logger.provider('JournalingBottomSheet | entry saved');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entrée enregistrée avec succès!'),
          backgroundColor: AkeliColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
          ),
        ),
      );
      Navigator.pop(context);
    }
  } on PostgrestException catch (e, st) {
    _logger.db('ERROR | table: journal_entry | code: ${e.code}', error: e, stackTrace: st);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de l\'enregistrement'),
          backgroundColor: AkeliColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
          ),
        ),
      );
    }
  } catch (e, st) {
    _logger.db('ERROR | journal_entry | unexpected | $e', error: e, stackTrace: st);
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
```

- [ ] Replace `_uploadMedia()` with a real image picker call:

```dart
Future<void> _uploadMedia() async {
  _logger.userAction('Add photo tapped', screen: 'JournalingBottomSheet');
  final images = await _picker.pickMultiImage(imageQuality: 80);
  if (images.isNotEmpty && mounted) {
    setState(() => _selectedImages = images);
  }
}
```

- [ ] In `build()`, update the media grid to use `_selectedImages` (replace `_uploadedMedia` references):

```dart
// Replace the condition guard:
_selectedImages.isEmpty

// Replace the GridView itemCount and itemBuilder:
itemCount: _selectedImages.length,
itemBuilder: (context, index) => ClipRRect(
  borderRadius: BorderRadius.circular(AkeliRadius.md),
  child: Image.file(
    File(_selectedImages[index].path),
    fit: BoxFit.cover,
  ),
),
```

- [ ] Add `dart:io` import for `File`:

```dart
import 'dart:io';
```

- [ ] Verify: `flutter analyze lib/features/journaling/journaling_bottom_sheet.dart` — 0 errors.

- [ ] Manual test: open the journaling sheet, pick a photo (verify thumbnail shows), fill description, save — check Supabase dashboard → `journal_entry` has a new row with correct `user_id`, `meal_type`, `description`.

- [ ] Commit:

```bash
git add lib/features/journaling/journaling_bottom_sheet.dart
git commit -m "feat: wire journaling_bottom_sheet to journal_entry table with image picker"
```

---

## Task 7 — Final verification and push

- [ ] Run full analyze:

```bash
flutter analyze
```

Expected: 0 errors. Warnings about unused imports are acceptable if pre-existing.

- [ ] Verify git log looks clean:

```bash
git log --oneline -8
```

Expected output (newest first):
```
feat: wire journaling_bottom_sheet to journal_entry table with image picker
feat: wire referral_page to DB — load code + count, save code to user_profile
feat: wire support_page to support_message table with real Supabase insert
feat(db): create journal_entry table with RLS
feat(db): add referral_code column to user_profile with default and index
fix: replace Navigator.pop with context.pop() on all GoRouter pages
fix: CLAUDE.md compliance, router structure, and cleanup
```

- [ ] Push to remote:

```bash
git push origin fix-compliance-and-router-issues-814be
```

---

## Manual Test Checklist (full branch)

Run through these on a connected device or emulator with a Supabase local or dev instance:

- [ ] Navigate to `/privacy-policy` — page loads, back button works (no bottom nav visible)
- [ ] Navigate to `/terms-of-service` — page loads, back button works (no bottom nav visible)
- [ ] Navigate to `/support` — email field pre-filled with logged-in user's email, form validates, submit creates a row in `support_message`, success snackbar shown, navigates back
- [ ] Navigate to `/referral` — loading spinner shown briefly, real code appears (not AKELI-SOFI unless that's the actual DB value), referral count matches DB, edit → type new code → save updates `user_profile.referral_code`
- [ ] Trigger `CookingSessionBottomSheet.show()` — "coming soon" sheet appears and dismisses correctly
- [ ] Trigger `JournalingBottomSheet.show()` — select a photo (thumbnail previews), fill description, choose meal type, save creates a row in `journal_entry`
