import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../shared/models/user_profile.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// UserProfile fetch — auto-refreshes on auth change
// ---------------------------------------------------------------------------

final userProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final data = await supabase
      .from('user_profile')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (data == null) return null;
  return UserProfile.fromJson(data);
});

final healthProfileProvider =
    FutureProvider.autoDispose<HealthProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final data = await supabase
      .from('user_health_profile')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();

  if (data == null) return null;
  return HealthProfile.fromJson(data);
});

// ---------------------------------------------------------------------------
// Profile update notifier
// ---------------------------------------------------------------------------

class UserProfileNotifier extends AutoDisposeAsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    final data = await supabase
        .from('user_profile')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (displayName != null) 'display_name': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    await supabase.from('user_profile').update(updates).eq('id', user.id);
    ref.invalidateSelf();
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

  return supabase
      .from('subscription')
      .select()
      .eq('user_id', user.id)
      .eq('status', 'active')
      .maybeSingle();
});

final isPremiumProvider = Provider.autoDispose<bool>((ref) {
  final sub = ref.watch(subscriptionProvider);
  return sub.maybeWhen(
    data: (data) => data != null,
    orElse: () => false,
  );
});
