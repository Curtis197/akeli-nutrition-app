import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/mock_data.dart';
import '../shared/models/creator.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// My fan subscription
// ---------------------------------------------------------------------------

final myFanSubscriptionProvider =
    FutureProvider.autoDispose<FanSubscription?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  await Future.delayed(const Duration(milliseconds: 500));
  return FanSubscription.fromJson(MockData.fanSubscription);
});

// ---------------------------------------------------------------------------
// Fan-eligible creators list
// ---------------------------------------------------------------------------

final fanEligibleCreatorsProvider =
    FutureProvider.autoDispose<List<Creator>>((ref) async {
  ref.watch(currentUserProvider);

  await Future.delayed(const Duration(milliseconds: 600));
  return MockData.creators.where((c) => c.isFanEligible).toList();
});

// ---------------------------------------------------------------------------
// Creator public profile
// ---------------------------------------------------------------------------

final creatorProfileProvider =
    FutureProvider.autoDispose.family<Creator?, String>((ref, creatorId) async {
  await Future.delayed(const Duration(milliseconds: 400));
  
  try {
    return MockData.creators.firstWhere((c) => c.id == creatorId);
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// Fan mode notifier — activate / cancel
// ---------------------------------------------------------------------------

class FanModeNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> activate(String creatorId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(seconds: 1));
      
      // Update local mock
      MockData.fanSubscription['creator_id'] = creatorId;
      MockData.fanSubscription['status'] = 'active';
      
      ref.invalidate(myFanSubscriptionProvider);
    });
  }

  Future<void> cancel() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(seconds: 1));
      
      // Update local mock
      MockData.fanSubscription['status'] = 'cancelled';
      
      ref.invalidate(myFanSubscriptionProvider);
    });
  }
}

final fanModeNotifierProvider =
    AsyncNotifierProvider.autoDispose<FanModeNotifier, void>(
        FanModeNotifier.new);
