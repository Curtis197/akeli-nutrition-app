import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/profile_tabs_provider.dart';
import '../../shared/widgets/avatar.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String? userId; // Optional, for viewing other profiles
  
  const ProfilePage({super.key, this.userId});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isCurrentUser = widget.userId == null || widget.userId == currentUser?.id;

    final profileAsync = ref.watch(userProfileProvider);
    final targetUserId = widget.userId ?? currentUser?.id ?? '';

    // When viewing another user, load their profile separately for the header
    final targetProfileAsync = isCurrentUser
        ? null
        : ref.watch(publicUserProfileProvider(targetUserId));
    // The profile shown in the header — own profile or the target's
    final displayProfile = isCurrentUser
        ? profileAsync.valueOrNull
        : targetProfileAsync?.valueOrNull;
    final isPrivate = !isCurrentUser && (displayProfile?.isPrivate ?? false);

    final userLikedRecipesAsync = ref.watch(userLikedRecipesProvider(targetUserId));
    final userCommentsAsync = ref.watch(userCommentsProvider(targetUserId));
    final userGroupsAsync = ref.watch(userGroupsProvider(targetUserId));
    
    return Scaffold(
      backgroundColor: AkeliColors.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 16),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: AkeliColors.surface.withValues(alpha: 0.8),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 8,
                left: 16,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: AkeliColors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back, color: AkeliColors.onSurfaceVariant),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AkeliRoutes.home);
                        }
                      },
                    ),
                  ),
                  Text(
                    displayProfile?.displayName ?? 'Profil',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (isCurrentUser)
                    Container(
                      decoration: const BoxDecoration(
                        color: AkeliColors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.settings_outlined, color: AkeliColors.onSurfaceVariant),
                        onPressed: () {
                          appLogger.userAction('Settings button tapped', screen: 'ProfilePage');
                          context.push(AkeliRoutes.settings);
                        },
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      body: (isCurrentUser
              ? profileAsync
              : targetProfileAsync ?? const AsyncValue.loading())
          .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (_) => SingleChildScrollView(
          child: Column(
            children: [
              // Hero & Profile
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Gradient
                  Positioned(
                    top: -100,
                    left: -50,
                    right: -50,
                    height: 400,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AkeliColors.primary.withValues(alpha: 0.15),
                            AkeliColors.surface.withValues(alpha: 0.8),
                            AkeliColors.tertiaryFixed.withValues(alpha: 0.15),
                          ],
                          radius: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + kToolbarHeight + 32,
                      left: 24,
                      right: 24,
                      bottom: 40,
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AkeliColors.primary.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AkeliColors.surfaceContainerLowest,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: AkeliAvatar(
                                imageUrl: displayProfile?.avatarUrl,
                                initials: (displayProfile?.displayName.isNotEmpty == true
                                        ? displayProfile!.displayName[0]
                                        : 'A')
                                    .toUpperCase(),
                                size: AvatarSize.lg,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Identity
                        Text(
                          displayProfile?.displayName.isNotEmpty == true 
                              ? displayProfile!.displayName 
                              : 'Utilisateur',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AkeliColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (displayProfile?.bio?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            displayProfile!.bio!,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AkeliColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 32),
                        // Action Buttons
                        if (isCurrentUser)
                          const SizedBox.shrink()
                        else
                          Consumer(builder: (context, ref, _) {
                            final convStateAsync = ref.watch(conversationStateProvider(widget.userId!));
                            
                            return convStateAsync.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (err, _) => const SizedBox.shrink(),
                              data: (convState) {
                                if (convState.status == ConvState.none) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                                            ),
                                            borderRadius: BorderRadius.circular(AkeliRadius.md),
                                          ),
                                          child: FilledButton.icon(
                                            onPressed: () async {
                                              appLogger.userAction('Start conversation tapped', screen: 'ProfilePage');
                                              try {
                                                await sendDmRequest(ref, widget.userId!);
                                                ref.invalidate(conversationStateProvider(widget.userId!));
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Demande envoyée')),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Erreur lors de l\'envoi de la demande')),
                                                  );
                                                }
                                              }
                                            },
                                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.white),
                                            label: Text('Démarrer une conversation', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.md)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else if (convState.status == ConvState.pending) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: null,
                                          icon: const Icon(Icons.access_time_rounded, size: 20),
                                          label: Text('En attente', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AkeliColors.textSecondary,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            side: BorderSide(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.md)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                                            ),
                                            borderRadius: BorderRadius.circular(AkeliRadius.md),
                                          ),
                                          child: FilledButton.icon(
                                            onPressed: () {
                                              appLogger.userAction('Message button tapped', screen: 'ProfilePage');
                                              context.push(AkeliRoutes.dmChatPath(convState.conversationId!), extra: displayProfile?.displayName ?? '');
                                            },
                                            icon: const Icon(Icons.chat_bubble_rounded, size: 20, color: Colors.white),
                                            label: Text('Message', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.md)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton(
                                        onPressed: () {
                                          appLogger.userAction('Close conversation tapped', screen: 'ProfilePage');
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Fermer la conversation ?'),
                                              content: const Text("Vous quitterez cette conversation. L'autre utilisateur gardera son historique."),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text('Annuler'),
                                                ),
                                                TextButton(
                                                  style: TextButton.styleFrom(foregroundColor: AkeliColors.error),
                                                  onPressed: () async {
                                                    Navigator.pop(ctx);
                                                    try {
                                                      await leaveDmConversation(ref, convState.conversationId!);
                                                      ref.invalidate(conversationStateProvider(widget.userId!));
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Conversation fermée')),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Erreur lors de la fermeture')),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: const Text('Fermer'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AkeliColors.error,
                                          backgroundColor: AkeliColors.surfaceContainerLowest,
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          side: BorderSide(color: AkeliColors.error.withValues(alpha: 0.3)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.md)),
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 20),
                                      ),
                                    ],
                                  );
                                }
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Content Section — hidden for private profiles
              if (isPrivate)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
                  decoration: const BoxDecoration(
                    color: AkeliColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 48, color: AkeliColors.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'Ce profil est privé',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Envoyez un message pour vous connecter.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AkeliColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 24, bottom: 48, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerLowest,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 48,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Tab Navigation
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: AkeliColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(AkeliRadius.pill),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AkeliColors.onSecondaryContainer,
                        unselectedLabelColor: AkeliColors.onSurfaceVariant,
                        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                        tabAlignment: TabAlignment.start,
                        splashFactory: NoSplash.splashFactory,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                        tabs: const [
                          Tab(text: 'Recettes'),
                          Tab(text: 'Commentaires'),
                          Tab(text: 'Groupes'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Tab Views
                      SizedBox(
                        height: 500, // Fixed height for now
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Recettes Tab
                            userLikedRecipesAsync.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => const Center(
                                child: Text('Erreur de chargement', style: TextStyle(color: AkeliColors.outline)),
                              ),
                              data: (recipes) {
                                if (recipes.isEmpty) {
                                  return const Center(
                                    child: Text('Aucune recette aimée', style: TextStyle(color: AkeliColors.outline)),
                                  );
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: recipes.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final r = recipes[index];
                                    return GestureDetector(
                                      onTap: () {
                                        context.push(AkeliRoutes.recipeDetailPath(r.id));
                                      },
                                      child: _ProfileRecipeCard(
                                        title: r.title,
                                        subtitle: '${r.totalTimeMin} min • ${r.difficulty}',
                                        rating: r.averageRating.toStringAsFixed(1),
                                        imageUrl: r.thumbnailUrl ?? '',
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            // Commentaires Tab
                            userCommentsAsync.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => const Center(
                                child: Text('Erreur de chargement', style: TextStyle(color: AkeliColors.outline)),
                              ),
                              data: (comments) {
                                if (comments.isEmpty) {
                                  return const Center(
                                    child: Text('Aucun commentaire', style: TextStyle(color: AkeliColors.outline)),
                                  );
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: comments.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final c = comments[index];
                                    final recipe = c['recipe'] as Map<String, dynamic>?;
                                    final recipeTitle = recipe?['title'] as String? ?? 'Recette inconnue';
                                    final recipeImage = recipe?['cover_image_url'] as String? ?? '';
                                    final content = c['content'] as String? ?? '';
                                    final rating = c['rating'] as int?;
                                    
                                    return _ProfileCommentCard(
                                      recipeTitle: recipeTitle,
                                      recipeImage: recipeImage,
                                      content: content,
                                      rating: rating,
                                    );
                                  },
                                );
                              },
                            ),
                            // Groupes Tab
                            userGroupsAsync.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => const Center(
                                child: Text('Erreur de chargement', style: TextStyle(color: AkeliColors.outline)),
                              ),
                              data: (groups) {
                                if (groups.isEmpty) {
                                  return const Center(
                                    child: Text('Aucun groupe', style: TextStyle(color: AkeliColors.outline)),
                                  );
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: groups.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final g = groups[index];
                                    final groupId = g['id'] as String;
                                    final title = g['name'] as String? ?? 'Groupe';
                                    final isPrivate = g['is_private'] as bool? ?? false;
                                    final memberCount = g['member_count'] as int? ?? 0;
                                    
                                    return _ProfileGroupCard(
                                      groupId: groupId,
                                      title: title,
                                      isPrivate: isPrivate,
                                      memberCount: memberCount,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRecipeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String rating;
  final String imageUrl;

  const _ProfileRecipeCard({
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AkeliRadius.md),
            child: Image.network(
              imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 96,
                height: 96,
                color: AkeliColors.surfaceContainerHigh,
                child: const Icon(Icons.broken_image, color: AkeliColors.outline),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AkeliColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: AkeliColors.accentAmber),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCommentCard extends StatelessWidget {
  final String recipeTitle;
  final String recipeImage;
  final String content;
  final int? rating;

  const _ProfileCommentCard({
    required this.recipeTitle,
    required this.recipeImage,
    required this.content,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AkeliRadius.sm),
            child: Image.network(
              recipeImage,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                color: AkeliColors.surfaceContainerHigh,
                child: const Icon(Icons.broken_image, color: AkeliColors.outline, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        recipeTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: AkeliColors.accentAmber),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AkeliColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AkeliColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileGroupCard extends StatelessWidget {
  final String groupId;
  final String title;
  final bool isPrivate;
  final int memberCount;

  const _ProfileGroupCard({
    required this.groupId,
    required this.title,
    required this.isPrivate,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AkeliRadius.md),
        onTap: () {
          appLogger.userAction('Group card tapped', screen: 'ProfilePage', metadata: {'groupId': groupId});
          context.push(AkeliRoutes.groupDetailPath(groupId));
        },
        child: Container(
          decoration: BoxDecoration(
            color: AkeliColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AkeliRadius.md),
            border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AkeliColors.primaryContainer,
              borderRadius: BorderRadius.circular(AkeliRadius.sm),
            ),
            child: Icon(
              isPrivate ? Icons.lock_rounded : Icons.public_rounded,
              color: AkeliColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$memberCount membre${memberCount > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AkeliColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
