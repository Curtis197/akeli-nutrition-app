import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/mock_data.dart';
import '../shared/models/user_profile.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// UserProfile fetch — auto-refreshes on auth change
// ---------------------------------------------------------------------------

final userProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  await Future.delayed(const Duration(milliseconds: 300));
  return MockData.currentUserProfile;
});

final healthProfileProvider =
    FutureProvider.autoDispose<HealthProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  await Future.delayed(const Duration(milliseconds: 400));
  return MockData.currentHealthProfile;
});

// ---------------------------------------------------------------------------
// Profile update notifier
// ---------------------------------------------------------------------------

class UserProfileNotifier extends AutoDisposeAsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.currentUserProfile;
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

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(seconds: 1));
      
      final updated = MockData.currentUserProfile.copyWith(
        username: username ?? MockData.currentUserProfile.username,
        firstName: firstName ?? MockData.currentUserProfile.firstName,
        lastName: lastName ?? MockData.currentUserProfile.lastName,
        bio: bio ?? MockData.currentUserProfile.bio,
        avatarUrl: avatarUrl ?? MockData.currentUserProfile.avatarUrl,
      );
      
      // Update global mock data
      // (Note: in a real app this would be a deep copy if it were more complex)
      // MockData's field is static, so we can reassign it.
      // But MockData.currentUserProfile is final. Let's assume we can't reassign easily without changing MockData.
      // For the sake of this mock, we just return the updated value in state.
      
      return updated;
    });
    
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

  await Future.delayed(const Duration(milliseconds: 500));
  return MockData.subscription;
});

final isPremiumProvider = Provider.autoDispose<bool>((ref) {
  final subAsync = ref.watch(subscriptionProvider);
  return subAsync.maybeWhen(
    data: (data) => data != null && data['status'] == 'active',
    orElse: () => false,
  );
});
