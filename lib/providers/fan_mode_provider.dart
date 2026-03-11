import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../shared/models/creator.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// My fan subscription
// ---------------------------------------------------------------------------

final myFanSubscriptionProvider =
    FutureProvider.autoDispose<FanSubscription?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final data = await supabase
      .from('fan_subscription')
      .select()
      .eq('user_id', user.id)
      .inFilter('status', ['active', 'pending'])
      .maybeSingle();

  if (data == null) return null;
  return FanSubscription.fromJson(data);
});

// ---------------------------------------------------------------------------
// Fan-eligible creators list
// ---------------------------------------------------------------------------

final fanEligibleCreatorsProvider =
    FutureProvider.autoDispose<List<Creator>>((ref) async {
  final user = ref.watch(currentUserProvider);

  final result = await supabase.rpc('search_creators', params: {
    'p_query': '',
    'p_limit': 50,
    'p_offset': 0,
  });

  return (result as List<dynamic>)
      .map((e) => Creator.fromJson(e as Map<String, dynamic>))
      .where((c) => c.isFanEligible)
      .toList();
});

// ---------------------------------------------------------------------------
// Creator public profile
// ---------------------------------------------------------------------------

final creatorProfileProvider =
    FutureProvider.autoDispose.family<Creator?, String>((ref, creatorId) async {
  final result = await supabase.rpc('get_creator_public_profile', params: {
    'p_creator_id': creatorId,
  });

  if (result == null) return null;
  return Creator.fromJson(result as Map<String, dynamic>);
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
      await supabase.functions.invoke(
        'activate-fan-mode',
        body: {'creator_id': creatorId},
      );
      ref.invalidate(myFanSubscriptionProvider);
    });
  }

  Future<void> cancel() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase.functions.invoke('cancel-fan-mode', body: {});
      ref.invalidate(myFanSubscriptionProvider);
    });
  }
}

final fanModeNotifierProvider =
    AsyncNotifierProvider.autoDispose<FanModeNotifier, void>(
        FanModeNotifier.new);
