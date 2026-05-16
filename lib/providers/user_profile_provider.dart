import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  final client = ref.watch(supabaseClientProvider);
  final data = await client
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

  final client = ref.watch(supabaseClientProvider);
  final data = await client
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

    final client = ref.watch(supabaseClientProvider);
    final data = await client
        .from('user_profile')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    String? avatarUrl,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final updates = <String, dynamic>{
      if (username != null) 'username': username,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    if (updates.isEmpty) return;

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await client
          .from('user_profile')
          .update(updates)
          .eq('id', user.id)
          .select()
          .single();
      return UserProfile.fromJson(data);
    });
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

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('subscription')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();
  return data;
});

final isPremiumProvider = Provider.autoDispose<bool>((ref) {
  final subAsync = ref.watch(subscriptionProvider);
  return subAsync.maybeWhen(
    data: (data) => data != null && data['status'] == 'active',
    orElse: () => false,
  );
});
