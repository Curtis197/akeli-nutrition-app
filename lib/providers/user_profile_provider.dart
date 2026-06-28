import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import '../shared/models/user_profile.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// UserProfile fetch
// ---------------------------------------------------------------------------

final userProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  appLogger.provider('userProfileProvider build() | userId: ${user.id}');
  ref.onDispose(() => appLogger.provider('userProfileProvider disposed'));
  appLogger.db('BEFORE | table: user_profile | op: SELECT | userId: ${user.id}');

  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('user_profile')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data == null) {
      appLogger.db('AFTER | table: user_profile | rows: 0 | userId: ${user.id}');
      appLogger.rls('Zero rows | table: user_profile | userId: ${user.id} | possible RLS block');
      appLogger.provider('userProfileProvider → data (null)');
      return null;
    }
    appLogger.db('AFTER | table: user_profile | rows: 1 | userId: ${user.id}');
    appLogger.provider('userProfileProvider → data | userId: ${user.id}');
    return UserProfile.fromJson(data);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: user_profile | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: user_profile | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('userProfileProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: user_profile | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('userProfileProvider → error | $e');
    rethrow;
  }
});

// Fetches another user's public profile — used when viewing someone else's profile page.
final publicUserProfileProvider =
    FutureProvider.autoDispose.family<UserProfile?, String>((ref, userId) async {
  appLogger.provider('publicUserProfileProvider build() | userId: $userId');
  ref.onDispose(() => appLogger.provider('publicUserProfileProvider disposed | userId: $userId'));

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: user_profile | op: SELECT | userId: $userId');

  try {
    final data = await client
        .from('user_profile')
        .select('id, first_name, last_name, username, avatar_url, bio, is_private, is_creator, created_at')
        .eq('id', userId)
        .maybeSingle();

    appLogger.db('AFTER | table: user_profile | rows: ${data == null ? 0 : 1}');
    if (data == null) {
      appLogger.rls('Zero rows | table: user_profile | userId: $userId | possible RLS block');
      return null;
    }
    appLogger.provider('publicUserProfileProvider → data | userId: $userId');
    return UserProfile.fromJson({
      ...data,
      'onboarding_done': true,
      'locale': 'fr',
    });
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: user_profile | userId: $userId', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: user_profile | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    appLogger.provider('publicUserProfileProvider → error | ${e.message}');
    rethrow;
  }
});

final healthProfileProvider =
    FutureProvider.autoDispose<HealthProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  appLogger.provider('healthProfileProvider build() | userId: ${user.id}');
  ref.onDispose(() => appLogger.provider('healthProfileProvider disposed'));
  appLogger.db('BEFORE | table: user_health_profile | op: SELECT | userId: ${user.id}');

  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('user_health_profile')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (data == null) {
      appLogger.db('AFTER | table: user_health_profile | rows: 0 | userId: ${user.id}');
      appLogger.rls('Zero rows | table: user_health_profile | userId: ${user.id} | possible RLS block');
      appLogger.provider('healthProfileProvider → data (null)');
      return null;
    }
    appLogger.db('AFTER | table: user_health_profile | rows: 1 | userId: ${user.id}');
    appLogger.provider('healthProfileProvider → data | userId: ${user.id}');
    return HealthProfile.fromJson(data);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: user_health_profile | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: user_health_profile | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('healthProfileProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: user_health_profile | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('healthProfileProvider → error | $e');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Profile update notifier
// ---------------------------------------------------------------------------

class UserProfileNotifier extends AutoDisposeAsyncNotifier<UserProfile?> {
  final _logger = appLogger;

  @override
  Future<UserProfile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    _logger.provider('UserProfileNotifier build() | userId: ${user.id}');
    ref.onDispose(() => _logger.provider('UserProfileNotifier disposed'));
    _logger.db('BEFORE | table: user_profile | op: SELECT | userId: ${user.id}');

    final client = ref.watch(supabaseClientProvider);
    try {
      final data = await client
          .from('user_profile')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data == null) {
        _logger.db('AFTER | table: user_profile | rows: 0 | userId: ${user.id}');
        _logger.rls('Zero rows | table: user_profile | userId: ${user.id} | possible RLS block');
        _logger.provider('UserProfileNotifier → data (null)');
        return null;
      }
      _logger.db('AFTER | table: user_profile | rows: 1 | userId: ${user.id}');
      _logger.provider('UserProfileNotifier → data | userId: ${user.id}');
      return UserProfile.fromJson(data);
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls('Permission denied | table: user_profile | userId: ${user.id}', error: e, stackTrace: st);
      } else {
        _logger.db('ERROR | table: user_profile | build | code: ${e.code}', error: e, stackTrace: st);
      }
      _logger.provider('UserProfileNotifier → error | ${e.message}');
      rethrow;
    } catch (e, st) {
      _logger.db('ERROR | table: user_profile | build | unexpected: $e', error: e, stackTrace: st);
      _logger.provider('UserProfileNotifier → error | $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    String? avatarUrl,
    bool? isPrivate,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final updates = <String, dynamic>{
      if (username != null) 'username': username,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (isPrivate != null) 'is_private': isPrivate,
    };
    if (updates.isEmpty) return;

    _logger.userAction('updateProfile', metadata: {'fields': updates.keys.toList()});
    _logger.db('BEFORE | table: user_profile | op: UPDATE | userId: ${user.id} | fields: ${updates.keys.toList()}');
    _logger.provider('UserProfileNotifier → loading (updateProfile)');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final data = await client
            .from('user_profile')
            .update(updates)
            .eq('id', user.id)
            .select()
            .single();
        _logger.db('AFTER | table: user_profile | op: UPDATE | rows: 1 | userId: ${user.id}');
        _logger.provider('UserProfileNotifier → data (updateProfile success)');
        return UserProfile.fromJson(data);
      } on PostgrestException catch (e, st) {
        if (e.code == '42501') {
          _logger.rls('Permission denied | table: user_profile | UPDATE | userId: ${user.id}', error: e, stackTrace: st);
        } else {
          _logger.db('ERROR | table: user_profile | UPDATE | code: ${e.code}', error: e, stackTrace: st);
        }
        _logger.provider('UserProfileNotifier → error (updateProfile)');
        rethrow;
      } catch (e, st) {
        _logger.db('ERROR | table: user_profile | UPDATE | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('UserProfileNotifier → error (updateProfile unexpected)');
        rethrow;
      }
    });
    if (state.hasValue) ref.invalidate(userProfileProvider);
  }

  Future<void> updateAvatar(File imageFile) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('updateAvatar');
    _logger.provider('UserProfileNotifier → loading (updateAvatar)');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final ext = imageFile.path.split('.').last.toLowerCase();
        final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

        _logger.db('BEFORE | storage: avatars | op: UPLOAD | path: $path');
        await client.storage.from('avatars').upload(path, imageFile, fileOptions: const FileOptions(upsert: true));
        _logger.db('AFTER | storage: avatars | op: UPLOAD | success');

        final publicUrl = client.storage.from('avatars').getPublicUrl(path);

        final data = await client
            .from('user_profile')
            .update({'avatar_url': publicUrl})
            .eq('id', user.id)
            .select()
            .single();
        _logger.db('AFTER | table: user_profile | op: UPDATE | avatar_url');

        return UserProfile.fromJson(data);
      } on StorageException catch (e, st) {
        _logger.db('ERROR | storage: avatars | UPLOAD | code: ${e.statusCode}', error: e, stackTrace: st);
        _logger.provider('UserProfileNotifier → error (updateAvatar)');
        rethrow;
      } catch (e, st) {
        _logger.db('ERROR | updateAvatar | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('UserProfileNotifier → error (updateAvatar)');
        rethrow;
      }
    });
    if (state.hasValue) ref.invalidate(userProfileProvider);
  }
}

final userProfileNotifierProvider =
    AsyncNotifierProvider.autoDispose<UserProfileNotifier, UserProfile?>(
        UserProfileNotifier.new);

// ---------------------------------------------------------------------------
// Subscription status
// ---------------------------------------------------------------------------

final subscriptionProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  appLogger.provider('subscriptionProvider build() | userId: ${user.id}');
  ref.onDispose(() => appLogger.provider('subscriptionProvider disposed'));
  appLogger.db('BEFORE | table: subscription | op: SELECT | userId: ${user.id}');

  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('subscription')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    appLogger.db('AFTER | table: subscription | rows: ${data == null ? 0 : 1} | userId: ${user.id}');
    if (data == null) {
      appLogger.rls('Zero rows | table: subscription | userId: ${user.id} | possible RLS block');
    }
    appLogger.provider('subscriptionProvider → data | status: ${data?['status'] ?? "none"}');
    return data;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: subscription | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: subscription | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('subscriptionProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: subscription | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('subscriptionProvider → error | $e');
    rethrow;
  }
});

final isPremiumProvider = Provider.autoDispose<bool>((ref) {
  appLogger.provider('isPremiumProvider evaluated');
  final subAsync = ref.watch(subscriptionProvider);
  final isPremium = subAsync.maybeWhen(
    data: (data) => data != null && data['status'] == 'active',
    orElse: () => false,
  );
  appLogger.provider('isPremiumProvider → isPremium: $isPremium');
  return isPremium;
});

// ---------------------------------------------------------------------------
// Hint dismissal — fire-and-forget upsert
// ---------------------------------------------------------------------------

final dismissMealScheduleHintProvider =
    FutureProvider.autoDispose.family<void, String>((ref, userId) async {
  appLogger.provider('dismissMealScheduleHintProvider | userId: ${LogHelper.maskUuid(userId)}');
  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: user_profile | op: UPDATE has_dismissed_meal_schedule_hint=true | userId: ${LogHelper.maskUuid(userId)}');
  try {
    await client
        .from('user_profile')
        .update({'has_dismissed_meal_schedule_hint': true})
        .eq('id', userId);
    appLogger.db('AFTER | table: user_profile | op: UPDATE | success');
    ref.invalidate(userProfileProvider);
  } on PostgrestException catch (e, st) {
    appLogger.db('ERROR | table: user_profile | UPDATE | ${e.message}', error: e, stackTrace: st);
    rethrow;
  }
});
