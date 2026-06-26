# Group — Exclude Member Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow a group admin to remove any member (including other admins) via a kebab menu on the member row; the removed user loses group and chat access and receives a push notification.

**Architecture:** A new Deno edge function `remove-group-member` handles all server-side logic atomically (admin check, delete from `group_member` + `conversation_participant`, push notification). The Flutter UI adds a `PopupMenuButton` to `_MemberRow` (admin-only, not self) and a `_onExcludeTap()` handler in `GroupDetailPage` that calls the function and refreshes the member list on success.

**Tech Stack:** Deno / TypeScript (edge function), Flutter / Dart / Riverpod (UI), Supabase client (supabase_flutter ^2.12.0)

---

## File Map

| File | Action |
|---|---|
| `supabase/functions/remove-group-member/index.ts` | **Create** |
| `lib/features/community/group_detail_page.dart` | **Modify** |

---

### Task 1: Edge function `remove-group-member`

**Files:**
- Create: `supabase/functions/remove-group-member/index.ts`

- [ ] **Step 1: Create the file with full implementation**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const SELF_URL = Deno.env.get("SUPABASE_URL")!;
const INTERNAL_SECRET = Deno.env.get("INTERNAL_SECRET")!;

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("remove-group-member");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    logger.debug("[STEP 1] Verify JWT");
    const { user } = await getAuthUser(req);
    if (!user) {
      logger.warn("EARLY RETURN | reason: unauthenticated");
      return unauthorized("Authentication required");
    }
    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    logger.debug("[STEP 2] Parse body");
    const body = await req.json();
    const { group_id, target_user_id } = body as {
      group_id?: string;
      target_user_id?: string;
    };

    if (!group_id || !target_user_id) {
      logger.warn("EARLY RETURN | reason: missing group_id or target_user_id");
      return err("group_id and target_user_id are required");
    }
    logger.debug("[STEP 2] Parsed | group_id: " + group_id + " | target: " + target_user_id);

    if (target_user_id === user.id) {
      logger.warn("EARLY RETURN | reason: self-removal attempt");
      return err("Cannot remove yourself from the group", 400);
    }

    const admin = serviceClient();

    logger.debug("[STEP 3] Verify caller is admin");
    logRLSCheck(logger, "group_member", "SELECT", user.id);
    const { data: membership, error: memberError } = await admin
      .from("group_member")
      .select("role")
      .eq("group_id", group_id)
      .eq("user_id", user.id)
      .eq("role", "admin")
      .maybeSingle();
    logQueryResult(logger, "group_member", "SELECT", membership ? 1 : 0, memberError ?? undefined);

    if (!membership) {
      logger.warn("EARLY RETURN | reason: caller not an admin | group_id: " + group_id);
      return unauthorized("Vous n'êtes pas administrateur");
    }

    logger.debug("[STEP 4] Verify target is a member");
    logRLSCheck(logger, "group_member", "SELECT", target_user_id);
    const { data: targetMembership, error: targetError } = await admin
      .from("group_member")
      .select("user_id")
      .eq("group_id", group_id)
      .eq("user_id", target_user_id)
      .maybeSingle();
    logQueryResult(logger, "group_member", "SELECT", targetMembership ? 1 : 0, targetError ?? undefined);

    if (!targetMembership) {
      logger.warn("EARLY RETURN | reason: target not a member | target: " + target_user_id);
      return err("User is not a member of this group", 404);
    }

    logger.debug("[STEP 5] Fetch group name");
    logRLSCheck(logger, "community_group", "SELECT", "all");
    const { data: group, error: groupError } = await admin
      .from("community_group")
      .select("name")
      .eq("id", group_id)
      .maybeSingle();
    logQueryResult(logger, "community_group", "SELECT", group ? 1 : 0, groupError ?? undefined);
    const groupName = group?.name ?? "Groupe";

    logger.debug("[STEP 6] Delete from group_member");
    logRLSCheck(logger, "group_member", "DELETE", target_user_id);
    const { error: deleteError } = await admin
      .from("group_member")
      .delete()
      .eq("group_id", group_id)
      .eq("user_id", target_user_id);
    logQueryResult(logger, "group_member", "DELETE", deleteError ? 0 : 1, deleteError ?? undefined);

    if (deleteError) throw deleteError;

    logger.debug("[STEP 7] Lookup conversation for group");
    logRLSCheck(logger, "conversation", "SELECT", "all");
    const { data: conversation, error: convError } = await admin
      .from("conversation")
      .select("id")
      .eq("community_group_id", group_id)
      .maybeSingle();
    logQueryResult(logger, "conversation", "SELECT", conversation ? 1 : 0, convError ?? undefined);

    if (conversation) {
      logger.debug("[STEP 8] Delete from conversation_participant | convId: " + conversation.id);
      logRLSCheck(logger, "conversation_participant", "DELETE", target_user_id);
      const { error: cpError } = await admin
        .from("conversation_participant")
        .delete()
        .eq("conversation_id", conversation.id)
        .eq("user_id", target_user_id);
      logQueryResult(logger, "conversation_participant", "DELETE", cpError ? 0 : 1, cpError ?? undefined);
      if (cpError) throw cpError;
    } else {
      logger.warn("[STEP 8] No conversation found for group | group_id: " + group_id);
    }

    logger.debug("[STEP 9] Send push notification to excluded user");
    const pushRes = await fetch(`${SELF_URL}/functions/v1/send-push-notification`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-internal-secret": INTERNAL_SECRET,
      },
      body: JSON.stringify({
        user_id: target_user_id,
        title: "Vous avez été retiré d'un groupe",
        body: `Vous avez été exclu du groupe : ${groupName}`,
        type: "group_exclusion",
        data: { group_id },
      }),
    });

    if (!pushRes.ok) {
      logger.warn("[STEP 9] Push notification failed | status: " + pushRes.status);
    }

    logger.info(`✅ EXIT | status: 200 | duration: ${Date.now() - start}ms`);
    return ok({ success: true });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
```

- [ ] **Step 2: Verify the file exists and TypeScript is valid**

```bash
deno check supabase/functions/remove-group-member/index.ts
```

Expected: no errors. If `deno` is not on PATH, skip — CI will catch it.

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/remove-group-member/index.ts
git commit -m "feat: add remove-group-member edge function"
```

---

### Task 2: Flutter UI — member row kebab menu + exclude handler

**Files:**
- Modify: `lib/features/community/group_detail_page.dart`

All changes are in one file. Make them in this order: `_MemberRow` → `_MembersTab` → `GroupDetailPage`.

- [ ] **Step 1: Add `onExcludeTap` to `_MemberRow`**

Add the `supabase_flutter` import at the top of the file (needed for `FunctionsHttpException`), add the field to `_MemberRow`, and add the kebab `PopupMenuButton` to its `build()` method.

Add to imports (after the existing imports):
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

Replace the entire `_MemberRow` class (lines 702–774) with:

```dart
class _MemberRow extends StatelessWidget {
  final GroupMember member;
  final bool isMe;
  final VoidCallback onDmTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onExcludeTap;

  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.onDmTap,
    required this.onProfileTap,
    this.onExcludeTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onProfileTap,
      borderRadius: BorderRadius.circular(AkeliRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AkeliSpacing.sm),
        child: Row(
          children: [
            AkeliAvatar(
              imageUrl: member.avatarUrl,
              initials: member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : '?',
              size: AvatarSize.md,
            ),
            const SizedBox(width: AkeliSpacing.md),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      member.displayName,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (member.role == 'admin') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AkeliColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Admin',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AkeliColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isMe)
              IconButton(
                icon: const Icon(Icons.mail_outline_rounded),
                color: AkeliColors.primary,
                tooltip: 'Message privé',
                onPressed: onDmTap,
              ),
            if (onExcludeTap != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AkeliColors.textSecondary),
                onSelected: (value) {
                  if (value == 'exclude') onExcludeTap!();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'exclude',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove_outlined, color: AkeliColors.error, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Exclure du groupe',
                          style: TextStyle(color: AkeliColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add `onExcludeTap` to `_MembersTab`**

Replace the `_MembersTab` class constructor and `build()` method to thread through the new callback. Replace from line 231 to 295:

```dart
class _MembersTab extends ConsumerWidget {
  final String groupId;
  final String? currentUserId;
  final bool isAdmin;
  final AsyncValue<List<GroupMember>> membersAsync;
  final void Function(GroupMember) onDmTap;
  final void Function(GroupMember) onExcludeTap;

  const _MembersTab({
    required this.groupId,
    required this.currentUserId,
    required this.isAdmin,
    required this.membersAsync,
    required this.onDmTap,
    required this.onExcludeTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      children: [
        AkeliSectionHeader(
          title: 'Membres',
          trailingLabel: isAdmin ? 'Inviter' : null,
          onTrailingTap: isAdmin
              ? () {
                  appLogger.userAction('Invite tapped', screen: 'GroupDetailPage');
                  _showInviteSheet(context, ref, groupId);
                }
              : null,
        ),
        const SizedBox(height: 12),
        membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (members) {
            if (members.isEmpty) {
              return const EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'Aucun membre',
                subtitle: 'Les membres apparaîtront ici.',
              );
            }
            return Column(
              children: members.map((member) {
                final isMe = member.userId == currentUserId;
                return _MemberRow(
                  member: member,
                  isMe: isMe,
                  onDmTap: () => onDmTap(member),
                  onProfileTap: () {
                    appLogger.userAction('Profile tapped',
                        screen: 'GroupDetailPage',
                        metadata: {'targetUserId': member.userId});
                    context.push(AkeliRoutes.userProfilePath(member.userId));
                  },
                  onExcludeTap: isAdmin && !isMe ? () => onExcludeTap(member) : null,
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
```

- [ ] **Step 3: Wire `onExcludeTap` in `GroupDetailPage.build()` and add `_onExcludeTap()`**

In `GroupDetailPage.build()`, update the `_MembersTab` instantiation (around line 172–178) to pass the new callback:

```dart
_MembersTab(
  groupId: widget.groupId,
  currentUserId: currentUserId,
  isAdmin: isAdmin,
  membersAsync: membersAsync,
  onDmTap: (member) => _onDmTap(context, member),
  onExcludeTap: (member) => _onExcludeTap(context, member),
),
```

Then add the `_onExcludeTap` method directly after `_onDmTap` (after line 226):

```dart
Future<void> _onExcludeTap(BuildContext context, GroupMember member) async {
  _logger.userAction('Exclude member tapped',
      screen: 'GroupDetailPage',
      metadata: {'targetUserId': member.userId});

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Exclure ${member.displayName} ?'),
      content: const Text(
          'Cette personne perdra l\'accès au groupe et au chat de groupe.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AkeliColors.error),
          child: const Text('Exclure'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final client = ref.read(supabaseClientProvider);
  _logger.edge('remove-group-member',
      'BEFORE | groupId: ${widget.groupId} | target: ${member.userId}');

  try {
    await client.functions.invoke(
      'remove-group-member',
      body: {
        'group_id': widget.groupId,
        'target_user_id': member.userId,
      },
    );
    _logger.edge('remove-group-member', 'AFTER | success');
    ref.invalidate(groupMembersProvider(widget.groupId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membre exclu du groupe')),
      );
    }
  } on FunctionsHttpException catch (e, st) {
    _logger.edge('remove-group-member',
        'ERROR | status: ${e.status} | ${e.message}',
        error: e, stackTrace: st);
    if (!context.mounted) return;
    if (e.status == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Vous n'êtes plus administrateur de ce groupe")),
      );
    } else if (e.status == 404) {
      // Target already removed — treat as success
      ref.invalidate(groupMembersProvider(widget.groupId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membre exclu du groupe')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Une erreur est survenue. Veuillez réessayer.')),
      );
    }
  } catch (e, st) {
    _logger.edge('remove-group-member', 'ERROR | $e', error: e, stackTrace: st);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Une erreur est survenue. Veuillez réessayer.')),
    );
  }
}
```

- [ ] **Step 4: Run Flutter analysis**

```bash
flutter analyze lib/features/community/group_detail_page.dart
```

Expected: no errors or warnings. Fix any that appear before continuing.

- [ ] **Step 5: Hot reload and manually verify**

Run the app and navigate to a group detail page as an admin:
1. The ⋮ icon should appear on every member row except your own row
2. Tapping ⋮ shows the "Exclure du groupe" menu item in red
3. Tapping "Exclure du groupe" shows the confirmation dialog with the member's name
4. Tapping "Annuler" closes the dialog without doing anything
5. Tapping "Exclure" calls the function and removes the member from the list
6. A "Membre exclu du groupe" SnackBar appears
7. As a non-admin, no ⋮ icon appears on any row

- [ ] **Step 6: Commit**

```bash
git add lib/features/community/group_detail_page.dart
git commit -m "feat: add exclude member UI for group admins"
```
