# Notification Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the in-app notification feed — DB triggers insert notifications on DM send and conversation request, a Riverpod provider fetches them, `NotificationsPage` displays typed cards with auto-mark-read on open, and a red dot badge appears on the shell bell icon.

**Architecture:** Postgres `AFTER INSERT` triggers on `chat_message` and `conversation_request` use `SECURITY DEFINER` functions to write directly into `notification` (no pg_net, no edge function calls). Flutter reads via `notificationsProvider` (FutureProvider.autoDispose), auto-marks all read in `initState`, and maps notification types to `AkeliNotifCard` variants. The bell in `MainShell` watches `unreadNotificationCountProvider` and overlays a red dot when count > 0.

**Tech Stack:** Flutter 3.x · Riverpod (flutter_riverpod) · Supabase (supabase_flutter) · GoRouter · flutter_test

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `supabase/migrations/20260524000006_notification_triggers.sql` | DB triggers + SECURITY DEFINER functions |
| Create | `lib/providers/notifications_provider.dart` | `notificationsProvider`, `unreadNotificationCountProvider`, `markAllNotificationsRead()` |
| Modify | `lib/features/notifications/notifications_page.dart` | Real list, ConsumerStatefulWidget, type-mapped cards, relative time |
| Modify | `lib/shared/widgets/main_shell.dart` | Red dot badge via `_NotificationBell` widget |
| Create | `test/features/notifications/notifications_page_test.dart` | Widget tests for empty, message, and request states |

---

### Task 1: DB Migration — Notification Triggers

**Files:**
- Create: `supabase/migrations/20260524000006_notification_triggers.sql`

- [ ] **Step 1: Create the migration file**

Create `supabase/migrations/20260524000006_notification_triggers.sql`:

```sql
-- ---------------------------------------------------------------------------
-- NOTIFICATION TRIGGERS
-- Inserts into `notification` when a DM is sent or a conversation request
-- is created. Both functions are SECURITY DEFINER so they can write to
-- `notification` regardless of the caller's RLS context.
-- ---------------------------------------------------------------------------

-- 1. DM message → notify recipient -----------------------------------------

CREATE OR REPLACE FUNCTION fn_notify_chat_message()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_sender_name  text;
  v_recipient_id uuid;
BEGIN
  -- Only handle private DMs (conversation_id set, group_id null)
  IF NEW.conversation_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT display_name INTO v_sender_name
    FROM user_profile WHERE id = NEW.sender_id;

  SELECT user_id INTO v_recipient_id
    FROM conversation_participant
   WHERE conversation_id = NEW.conversation_id
     AND user_id != NEW.sender_id
   LIMIT 1;

  IF v_recipient_id IS NOT NULL THEN
    INSERT INTO notification (user_id, type, title, body, data)
    VALUES (
      v_recipient_id,
      'message',
      COALESCE(v_sender_name, 'Nouveau message'),
      LEFT(NEW.content, 100),
      jsonb_build_object(
        'conversation_id', NEW.conversation_id,
        'sender_id',       NEW.sender_id
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_chat_message
  AFTER INSERT ON chat_message
  FOR EACH ROW
  EXECUTE FUNCTION fn_notify_chat_message();

-- 2. Conversation request → notify recipient --------------------------------

CREATE OR REPLACE FUNCTION fn_notify_conversation_request()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_requester_name text;
BEGIN
  SELECT display_name INTO v_requester_name
    FROM user_profile WHERE id = NEW.requester_id;

  INSERT INTO notification (user_id, type, title, body, data)
  VALUES (
    NEW.recipient_id,
    'conversation_request',
    COALESCE(v_requester_name, 'Quelqu''un') || ' veut discuter',
    'Acceptez ou refusez la demande de conversation.',
    jsonb_build_object(
      'request_id',   NEW.id,
      'requester_id', NEW.requester_id
    )
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_conversation_request
  AFTER INSERT ON conversation_request
  FOR EACH ROW
  EXECUTE FUNCTION fn_notify_conversation_request();
```

- [ ] **Step 2: Push to local Supabase**

```bash
supabase db push
```

Expected output: migration `20260524000006_notification_triggers` applied with no errors.

- [ ] **Step 3: Smoke-test the triggers in Supabase Studio**

Open `http://127.0.0.1:54323` → SQL Editor, run:

```sql
-- Verify functions exist
SELECT proname FROM pg_proc
WHERE proname IN ('fn_notify_chat_message', 'fn_notify_conversation_request');

-- Verify triggers exist
SELECT tgname, relname
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE tgname IN ('trg_notify_chat_message', 'trg_notify_conversation_request');
```

Expected: 2 rows from `pg_proc`, 2 rows from `pg_trigger`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260524000006_notification_triggers.sql
git commit -m "feat(db): add notification triggers for DM and conversation_request"
```

---

### Task 2: `notifications_provider.dart`

**Files:**
- Create: `lib/providers/notifications_provider.dart`

- [ ] **Step 1: Create the provider file**

Create `lib/providers/notifications_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/supabase_client.dart';
import 'auth_provider.dart';

final _logger = appLogger;

// ---------------------------------------------------------------------------
// notificationsProvider
// Fetches the 50 most recent notifications for the current user.
// ---------------------------------------------------------------------------

final notificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    _logger.provider('notificationsProvider → [] (no user)');
    return [];
  }

  _logger.provider('notificationsProvider build() | userId: ${user.id}');
  ref.onDispose(() => _logger.provider('notificationsProvider disposed'));

  final client = ref.watch(supabaseClientProvider);

  _logger.db(
      'BEFORE | table: notification | op: SELECT | userId: ${user.id}');
  try {
    final data = await client
        .from('notification')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    final rows = List<Map<String, dynamic>>.from(data as List);
    _logger.db('AFTER | table: notification | rows: ${rows.length}');

    if (rows.isEmpty) {
      _logger.rls(
          'Zero rows | table: notification | userId: ${user.id} | possible RLS block');
    }

    _logger.provider(
        'notificationsProvider → data | count: ${rows.length}');
    return rows;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls(
          'Permission denied | table: notification | userId: ${user.id}',
          error: e,
          stackTrace: st);
    } else {
      _logger.db(
          'ERROR | table: notification | code: ${e.code} | ${e.message}',
          error: e,
          stackTrace: st);
    }
    _logger.provider('notificationsProvider → error | ${e.message}');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// unreadNotificationCountProvider
// Returns the count of unread notifications. Used for the bell badge.
// ---------------------------------------------------------------------------

final unreadNotificationCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  _logger.provider(
      'unreadNotificationCountProvider build() | userId: ${user.id}');
  ref.onDispose(
      () => _logger.provider('unreadNotificationCountProvider disposed'));

  final client = ref.watch(supabaseClientProvider);

  _logger.db(
      'BEFORE | table: notification | op: SELECT unread count | userId: ${user.id}');
  try {
    final data = await client
        .from('notification')
        .select()
        .eq('user_id', user.id)
        .eq('is_read', false);

    final count = (data as List).length;
    _logger.db('AFTER | table: notification | unread count: $count');
    _logger.provider(
        'unreadNotificationCountProvider → data | count: $count');
    return count;
  } on PostgrestException catch (e, st) {
    _logger.db(
        'ERROR | table: notification | unread count | code: ${e.code}',
        error: e,
        stackTrace: st);
    _logger.provider(
        'unreadNotificationCountProvider → error | ${e.message}');
    return 0;
  }
});

// ---------------------------------------------------------------------------
// markAllNotificationsRead
// Called from NotificationsPage.initState(). Updates is_read = true for all
// unread notifications, then invalidates both providers.
// ---------------------------------------------------------------------------

Future<void> markAllNotificationsRead(WidgetRef ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final client = ref.read(supabaseClientProvider);

  _logger.db(
      'BEFORE | table: notification | op: UPDATE is_read | userId: ${user.id}');
  try {
    await client
        .from('notification')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);

    _logger.db(
        'AFTER | table: notification | op: UPDATE is_read | success');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls(
          'Permission denied | table: notification | UPDATE | userId: ${user.id}',
          error: e,
          stackTrace: st);
    } else {
      _logger.db(
          'ERROR | table: notification | UPDATE is_read | code: ${e.code}',
          error: e,
          stackTrace: st);
    }
  }

  ref.invalidate(notificationsProvider);
  ref.invalidate(unreadNotificationCountProvider);
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/providers/notifications_provider.dart
```

Expected: no errors, no warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/notifications_provider.dart
git commit -m "feat: add notificationsProvider and markAllNotificationsRead"
```

---

### Task 3: Wire `NotificationsPage`

**Files:**
- Modify: `lib/features/notifications/notifications_page.dart`
- Create: `test/features/notifications/notifications_page_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Create `test/features/notifications/notifications_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/features/notifications/notifications_page.dart';
import 'package:akeli/providers/notifications_provider.dart';

Widget _testApp(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: buildLightTheme(),
        home: child,
      ),
    );

void main() {
  group('NotificationsPage', () {
    testWidgets('shows empty state when no notifications', (tester) async {
      await tester.pumpWidget(_testApp(
        const NotificationsPage(),
        overrides: [
          notificationsProvider.overrideWith((_) async => []),
          unreadNotificationCountProvider.overrideWith((_) async => 0),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Aucune notification'), findsOneWidget);
    });

    testWidgets('shows chat card for message notification', (tester) async {
      final notif = {
        'id': 'n1',
        'type': 'message',
        'title': 'Marie Dupont',
        'body': 'Bonjour !',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'data': {'conversation_id': 'c1', 'sender_id': 's1'},
      };
      await tester.pumpWidget(_testApp(
        const NotificationsPage(),
        overrides: [
          notificationsProvider.overrideWith((_) async => [notif]),
          unreadNotificationCountProvider.overrideWith((_) async => 1),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Marie Dupont'), findsOneWidget);
      expect(find.text('Bonjour !'), findsOneWidget);
    });

    testWidgets('shows request card with Accept/Decline for conversation_request',
        (tester) async {
      final notif = {
        'id': 'n2',
        'type': 'conversation_request',
        'title': 'Jean Martin veut discuter',
        'body': 'Acceptez ou refusez la demande de conversation.',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'data': {'request_id': 'r1', 'requester_id': 'u1'},
      };
      await tester.pumpWidget(_testApp(
        const NotificationsPage(),
        overrides: [
          notificationsProvider.overrideWith((_) async => [notif]),
          unreadNotificationCountProvider.overrideWith((_) async => 1),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Jean Martin veut discuter'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
flutter test test/features/notifications/notifications_page_test.dart -v
```

Expected: FAIL — `NotificationsPage` is still a stub that shows empty state regardless.

- [ ] **Step 3: Replace `notifications_page.dart` with the real implementation**

Full replacement of `lib/features/notifications/notifications_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/notifications_provider.dart';
import 'package:akeli/providers/dm_provider.dart';
import 'package:akeli/shared/widgets/empty_state.dart';
import 'package:akeli/shared/widgets/notif_card.dart';

final _logger = appLogger;

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    _logger.provider('NotificationsPage initState()');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markAllNotificationsRead(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('NotificationsPage build()');
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Notifications'),
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          _logger.provider('NotificationsPage → error | $e');
          return const EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'Aucune notification',
            subtitle: 'Vous recevrez ici vos rappels de repas et messages.',
          );
        },
        data: (notifications) {
          _logger.provider(
              'NotificationsPage → data | count: ${notifications.length}');
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Aucune notification',
              subtitle: 'Vous recevrez ici vos rappels de repas et messages.',
            );
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) =>
                _buildCard(notifications[index]),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> notif) {
    final type = notif['type'] as String? ?? '';
    final title = notif['title'] as String? ?? '';
    final body = notif['body'] as String? ?? '';
    final createdAt = notif['created_at'] as String? ?? '';
    final data = (notif['data'] as Map<String, dynamic>?) ?? {};

    switch (type) {
      case 'message':
        return AkeliNotifCard(
          type: NotifType.chat,
          title: title,
          subtitle: body,
          time: _relativeTime(createdAt),
        );

      case 'conversation_request':
        final requestId = data['request_id'] as String? ?? '';
        final requesterId = data['requester_id'] as String? ?? '';
        return AkeliNotifCard(
          type: NotifType.request,
          title: title,
          subtitle: body,
          time: _relativeTime(createdAt),
          onAccept: requestId.isEmpty
              ? null
              : () {
                  _logger.userAction('Accept DM request tapped',
                      screen: 'NotificationsPage',
                      metadata: {'request_id': requestId});
                  acceptDmRequest(ref, requestId, requesterId).then((_) {
                    ref.invalidate(notificationsProvider);
                  }).catchError((e) {
                    _logger.db('ERROR | acceptDmRequest | $e');
                  });
                },
          onDecline: requestId.isEmpty
              ? null
              : () {
                  _logger.userAction('Decline DM request tapped',
                      screen: 'NotificationsPage',
                      metadata: {'request_id': requestId});
                  rejectDmRequest(ref, requestId).then((_) {
                    ref.invalidate(notificationsProvider);
                  }).catchError((e) {
                    _logger.db('ERROR | rejectDmRequest | $e');
                  });
                },
        );

      case 'meal_reminder':
        final mealType = data['meal_type'] as String? ?? '';
        return AkeliNotifCard(
          type: NotifType.meal,
          title: title,
          subtitle: body,
          time: _relativeTime(createdAt),
          emoji: _mealEmoji(mealType),
        );

      default:
        return AkeliNotifCard(
          type: NotifType.meal,
          title: title,
          subtitle: body,
          time: _relativeTime(createdAt),
          emoji: '🔔',
        );
    }
  }
}

String _relativeTime(String isoString) {
  final dt = DateTime.tryParse(isoString);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'Hier';
  return 'Il y a ${diff.inDays} j';
}

String _mealEmoji(String mealType) {
  switch (mealType) {
    case 'breakfast': return '🥣';
    case 'lunch':     return '🍽️';
    case 'dinner':    return '🌙';
    case 'snack':     return '🍎';
    default:          return '🍽️';
  }
}
```

- [ ] **Step 4: Run tests — expect all to pass**

```bash
flutter test test/features/notifications/notifications_page_test.dart -v
```

Expected: all 3 tests PASS.

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/features/notifications/notifications_page.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/notifications/notifications_page.dart \
        test/features/notifications/notifications_page_test.dart
git commit -m "feat: wire NotificationsPage with real notification list and type-mapped cards"
```

---

### Task 4: Bell Badge in `main_shell.dart`

**Files:**
- Modify: `lib/shared/widgets/main_shell.dart`

- [ ] **Step 1: Add the notifications provider import**

In `lib/shared/widgets/main_shell.dart`, add after the existing imports:

```dart
import '../../providers/notifications_provider.dart';
```

- [ ] **Step 2: Replace the bare bell `IconButton` with `_NotificationBell`**

Locate this block in `lib/shared/widgets/main_shell.dart` (inside `actions`):

```dart
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: AkeliColors.secondary),
            onPressed: () => context.push(AkeliRoutes.notifications),
            tooltip: 'Notifications',
          ),
```

Replace it with:

```dart
          const _NotificationBell(),
```

- [ ] **Step 3: Add `_NotificationBell` widget class**

At the bottom of `lib/shared/widgets/main_shell.dart`, before the `_TabItem` class, add:

```dart
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadNotificationCountProvider);
    final hasUnread =
        countAsync.maybeWhen(data: (n) => n > 0, orElse: () => false);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: AkeliColors.secondary),
          onPressed: () => context.push(AkeliRoutes.notifications),
          tooltip: 'Notifications',
        ),
        if (hasUnread)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/shared/widgets/main_shell.dart
```

Expected: no errors.

- [ ] **Step 5: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets/main_shell.dart
git commit -m "feat: add unread red dot badge on notification bell"
```

---

## Self-Review

**Spec coverage:**
- ✅ DB trigger for `chat_message` (DM-only, skips group) → Task 1
- ✅ DB trigger for `conversation_request` → Task 1
- ✅ `notificationsProvider` (FutureProvider, SELECT 50, logging) → Task 2
- ✅ `unreadNotificationCountProvider` → Task 2
- ✅ `markAllNotificationsRead()` (UPDATE + invalidate) → Task 2
- ✅ Auto-mark on open via `initState` + `addPostFrameCallback` → Task 3
- ✅ Type mapping: message/conversation_request/meal_reminder/default → Task 3
- ✅ Relative time display → Task 3
- ✅ Accept/Decline callbacks with `acceptDmRequest` / `rejectDmRequest` → Task 3
- ✅ Red dot badge on bell → Task 4
- ✅ Full logging standard (BEFORE/AFTER/ERROR + userAction) → Tasks 2 & 3

**Placeholder scan:** none — all code blocks are complete.

**Type consistency:**
- `markAllNotificationsRead(WidgetRef ref)` defined Task 2, called Task 3 ✅
- `notificationsProvider` / `unreadNotificationCountProvider` defined Task 2, used Tasks 3 & 4, overridden in tests ✅
- `acceptDmRequest(ref, requestId, requesterId)` matches `dm_provider.dart:557` signature ✅
- `rejectDmRequest(ref, requestId)` matches `dm_provider.dart:611` signature ✅
- `_NotificationBell` declared `const` in Task 4 Step 3 → used as `const _NotificationBell()` in Step 2 ✅
