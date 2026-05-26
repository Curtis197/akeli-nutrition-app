import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
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
    // For now we assume we're viewing the current user if userId is null
    final isCurrentUser = widget.userId == null; 
    bool isPrivate = false; // Mocking privacy state for now
    
    final profileAsync = ref.watch(userProfileProvider);
    
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
                        Row(
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
                                    appLogger.userAction('Ajouter button tapped', screen: 'ProfilePage');
                                  },
                                  icon: const Icon(Icons.add, size: 20, color: Colors.white),
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  appLogger.userAction('Ecrire button tapped', screen: 'ProfilePage');
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
                          ],
                        ),
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
                            ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: 3,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final recipes = [
                                  _RecipeMock('Salade d\'Été aux Agrumes', '15 min • Végétarien', '4.9', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&auto=format&fit=crop'),
                                  _RecipeMock('Tartine Avocat & Sésame', '10 min • Vegan', '4.7', 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=800&auto=format&fit=crop'),
                                  _RecipeMock('Bol Énergie Açaí', '5 min • Petit-déjeuner', '5.0', 'https://images.unsplash.com/photo-1494597564530-871f2b93ac55?w=800&auto=format&fit=crop'),
                                ];
                                final r = recipes[index];
                                return _ProfileRecipeCard(
                                  title: r.title,
                                  subtitle: r.subtitle,
                                  rating: r.rating,
                                  imageUrl: r.img,
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

class _RecipeMock {
  final String title;
  final String subtitle;
  final String rating;
  final String img;
  _RecipeMock(this.title, this.subtitle, this.rating, this.img);
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
