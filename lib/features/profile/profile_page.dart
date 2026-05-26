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
import '../../providers/recipe_provider.dart';
import '../../providers/user_profile_provider.dart';
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
    final isCurrentUser = widget.userId == null;
    bool isPrivate = false;

    final profileAsync = ref.watch(userProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final targetUserId = widget.userId ?? currentUser?.id ?? '';
    final userRecipesAsync = ref.watch(userRecipesProvider(targetUserId));
    
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
                    'Akeli Oasis',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (profile) => SingleChildScrollView(
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
                                imageUrl: profile?.avatarUrl,
                                initials: (profile?.displayName.isNotEmpty == true
                                        ? profile!.displayName[0]
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
                          profile?.displayName ?? 'Utilisateur',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AkeliColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile?.bio?.isNotEmpty == true
                              ? profile!.bio!
                              : 'Curating wellness & culinary serenity.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AkeliColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
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
                                              appLogger.userAction('Ajouter button tapped', screen: 'ProfilePage');
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
                                            icon: const Icon(Icons.person_add_rounded, size: 20, color: Colors.white),
                                            label: Text('Ajouter', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
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
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            appLogger.userAction('Ecrire button tapped', screen: 'ProfilePage');
                                            context.push(AkeliRoutes.dmChatPath(convState.conversationId!), extra: profile?.displayName ?? '');
                                          },
                                          icon: const Icon(Icons.edit, size: 20),
                                          label: Text('Ecrire', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AkeliColors.primary,
                                            backgroundColor: AkeliColors.surfaceContainerLowest,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            side: BorderSide(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.md)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            appLogger.userAction('Supprimer button tapped', screen: 'ProfilePage');
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
                                          icon: const Icon(Icons.close_rounded, size: 20),
                                          label: Text('Supprimer', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AkeliColors.error,
                                            backgroundColor: AkeliColors.surfaceContainerLowest,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            side: BorderSide(color: AkeliColors.error.withValues(alpha: 0.3)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.md)),
                                          ),
                                        ),
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
              
              // Content Section
              if (isPrivate && !isCurrentUser)
                // Private State
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: const BoxDecoration(
                    color: AkeliColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline, size: 48, color: AkeliColors.outline),
                      const SizedBox(height: 16),
                      Text(
                        'Ce profil est privé',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.onSurface,
                        ),
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
                            userRecipesAsync.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => const Center(
                                child: Text('Erreur de chargement', style: TextStyle(color: AkeliColors.outline)),
                              ),
                              data: (recipes) {
                                if (recipes.isEmpty) {
                                  return const Center(
                                    child: Text('Aucune recette', style: TextStyle(color: AkeliColors.outline)),
                                  );
                                }
                                return ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: recipes.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final r = recipes[index];
                                    return _ProfileRecipeCard(
                                      title: r.title,
                                      subtitle: '${r.totalTimeMin} min • ${r.difficulty}',
                                      rating: r.averageRating.toStringAsFixed(1),
                                      imageUrl: r.thumbnailUrl ?? '',
                                    );
                                  },
                                );
                              },
                            ),
                            // Commentaires Tab
                            const Center(child: Text('Aucun commentaire', style: TextStyle(color: AkeliColors.outline))),
                            // Groupes Tab
                            const Center(child: Text('Aucun groupe', style: TextStyle(color: AkeliColors.outline))),
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
