import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/supabase_client.dart';
import '../shared/models/recipe_comment.dart';
import '../core/logger.dart';
import 'recipe_provider.dart';

part 'recipe_comment_provider.g.dart';

@riverpod
class RecipeCommentNotifier extends _$RecipeCommentNotifier {
  final _logger = appLogger;

  @override
  FutureOr<List<RecipeComment>> build(String recipeId) async {
    return _fetchComments();
  }

  Future<List<RecipeComment>> _fetchComments() async {
    _logger.db('Fetching comments for recipe: $recipeId');
    try {
      final response = await ref.read(supabaseClientProvider)
          .from('recipe_comment')
          .select('*, user_profile(username, first_name, last_name, avatar_url)')
          .eq('recipe_id', recipeId)
          .order('created_at', ascending: false);

      final comments = (response as List<dynamic>)
          .map((json) => RecipeComment.fromJson(json as Map<String, dynamic>))
          .toList();

      return comments;
    } catch (e, st) {
      _logger.db('Failed to fetch comments', error: e, stackTrace: st);
      throw Exception('Failed to fetch comments');
    }
  }

  Future<void> postComment(String content) async {
    _logger.userAction('Posting comment on recipe: $recipeId');
    
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) {
      _logger.auth('User must be logged in to post a comment');
      throw Exception('User must be logged in to post a comment');
    }

    try {
      // Optimistic update could be done here, but let's just wait for DB
      await ref.read(supabaseClientProvider).from('recipe_comment').insert({
        'recipe_id': recipeId,
        'user_id': userId,
        'content': content.trim(),
      });

      // Refetch the comments
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetchComments());

      // Invalidate recipe providers so UI refreshes the comment_count
      ref.invalidate(recipeDetailProvider(recipeId));
      ref.invalidate(feedProvider);
      
    } catch (e, st) {
      _logger.db('Failed to post comment', error: e, stackTrace: st);
      throw Exception('Failed to post comment');
    }
  }
}
