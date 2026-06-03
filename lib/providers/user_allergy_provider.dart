import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/logger.dart';
import '../../core/supabase_client.dart';
import '../features/settings/models/allergen_model.dart';
import 'auth_provider.dart';

part 'user_allergy_provider.g.dart';

@riverpod
class UserAllergy extends _$UserAllergy {
  final _logger = appLogger;

  @override
  Future<List<AllergenModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final client = ref.watch(supabaseClientProvider);
    _logger.db('BEFORE | user_allergy joined with allergen | userId: ${user.id}');
    try {
      final res = await client
          .from('user_allergy')
          .select('allergen:allergen_id ( id, slug, label )')
          .eq('user_id', user.id);

      _logger.db('AFTER | user_allergy | loaded ${res.length} rows');

      return res.map((row) {
        final allergenData = row['allergen'] as Map<String, dynamic>;
        return AllergenModel.fromJson(allergenData);
      }).toList();
    } catch (e, st) {
      _logger.db('ERROR | user_allergy', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> addAllergy(String allergenId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    final client = ref.read(supabaseClientProvider);
    _logger.userAction('addAllergy | allergenId: $allergenId');

    try {
      await client.from('user_allergy').insert({
        'user_id': user.id,
        'allergen_id': allergenId,
      });
      ref.invalidateSelf();
    } catch (e, st) {
      _logger.db('ERROR | addAllergy', error: e, stackTrace: st);
    }
  }

  Future<void> removeAllergy(String allergenId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    final client = ref.read(supabaseClientProvider);
    _logger.userAction('removeAllergy | allergenId: $allergenId');

    try {
      await client
          .from('user_allergy')
          .delete()
          .eq('user_id', user.id)
          .eq('allergen_id', allergenId);
      
      final currentList = state.valueOrNull ?? [];
      state = AsyncData(currentList.where((a) => a.id != allergenId).toList());
    } catch (e, st) {
      _logger.db('ERROR | removeAllergy', error: e, stackTrace: st);
    }
  }
}
