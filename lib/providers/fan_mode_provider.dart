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

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('fan_subscription')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();
  if (data == null) return null;
  return FanSubscription.fromJson(data);
});

// ---------------------------------------------------------------------------
// Fan-eligible creators (all creators — no is_fan_eligible column in DB)
// ---------------------------------------------------------------------------

final fanEligibleCreatorsProvider =
    FutureProvider.autoDispose<List<Creator>>((ref) async {
  ref.watch(currentUserProvider);

  final client = ref.watch(supabaseClientProvider);
  final data = await client.from('creator').select();

  return data.map(Creator.fromJson).where((c) => c.isFanEligible).toList();
});

// ---------------------------------------------------------------------------
// Creator public profile
// ---------------------------------------------------------------------------

final creatorProfileProvider =
    FutureProvider.autoDispose.family<Creator?, String>((ref, creatorId) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('creator')
      .select()
      .eq('id', creatorId)
      .maybeSingle();
  if (data == null) return null;
  return Creator.fromJson(data);
});

// ---------------------------------------------------------------------------
// Fan mode notifier — activate / cancel via Edge Functions
// ---------------------------------------------------------------------------

class FanModeNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> activate(String creatorId) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.functions.invoke(
        'activate-fan-mode',
        body: {'creator_id': creatorId},
      );
    });
    if (state is AsyncData) ref.invalidate(myFanSubscriptionProvider);
  }

  Future<void> cancel() async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.functions.invoke('cancel-fan-mode', body: {});
    });
    if (state is AsyncData) ref.invalidate(myFanSubscriptionProvider);
  }
}

final fanModeNotifierProvider =
    AsyncNotifierProvider.autoDispose<FanModeNotifier, void>(
        FanModeNotifier.new);
