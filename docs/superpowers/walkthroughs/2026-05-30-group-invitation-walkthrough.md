# Walkthrough: Group Invitation Design (2026-05-30)

## Overview
This walkthrough summarizes the implementation of the `2026-05-30-group-invitation-design.md` spec to allow group admins to invite direct messaging connections to their groups.

## Changes Made
1. **Database Migration (`20260530000004_group_invite.sql`)**:
   - Created the `group_invite` table to track invitations (`id`, `group_id`, `inviter_id`, `invitee_id`, `status`).
   - Defined strict Row-Level Security (RLS) policies allowing admins to insert invites and invitees to view/update them.
   - Built a secure RPC function `accept_group_invite` (SECURITY DEFINER) which inserts the user into `community_member` and their linked `conversation_participant` automatically.

2. **Edge Function (`invite-to-group`)**:
   - Implemented a secure edge function to fan out invitations from an admin to multiple select invitees.
   - Included robust `CLAUDE.md` compliant logging and error handling.
   - Registered the function in `supabase/config.toml`.

3. **Flutter UI Implementation (`GroupDetailPage`)**:
   - Added an 'Inviter' trailing action to the 'Membres' section, visible only to admins.
   - Implemented an `_InviteSheet` modal bottom sheet.
   - Used `pendingGroupInvitesProvider` to filter out users who are already in the group or have a pending invitation.
   - Triggered the `invite-to-group` edge function via the Supabase client.

4. **Flutter UI Implementation (`NotificationsPage`)**:
   - Handled the `group_invite` notification type.
   - Provided Accept/Decline callbacks to trigger `accept_group_invite` RPC or update the invite status directly.
   - Showed a SnackBar with an action to navigate to the newly joined group.

## Verification
- Admins can open the `_InviteSheet` and see their eligible DMs.
- Invites are sent successfully via edge function.
- Invitees receive notifications with Accept/Decline capabilities.
- Accepting an invite successfully adds the member to the group and its chat conversation.
