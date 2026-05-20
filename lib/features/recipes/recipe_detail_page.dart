import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/recipe_provider.dart';
import '../../shared/models/recipe.dart';
import '../../shared/widgets/empty_state.dart';
import 'domain/entities/recipe_tracking.dart';
import 'presentation/providers/recipe_tracking_provider.dart';

class RecipeDetailPage extends ConsumerStatefulWidget {
  final String recipeId;
  final TrackingSource source;

  const RecipeDetailPage({
    super.key,
    required this.recipeId,
    this.source = TrackingSource.feed,
  });

  @override
  ConsumerState<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends ConsumerState<RecipeDetailPage> {
  final _logger = appLogger;
  int _currentImageIndex = 0;
  final _pageController = PageController();

  // Tracking state
  RecipeOpen? _currentOpen;

  @override
  void initState() {
    super.initState();
    _logger.provider('RecipeDetailPage initState() | recipeId: ${widget.recipeId} | source: ${widget.source}');
    _trackOpen();
  }

  Future<void> _trackOpen() async {
    try {
      _logger.db('BEFORE | op: trackOpen | recipeId: ${widget.recipeId} | source: ${widget.source}');
      _currentOpen = await ref
          .read(recipeTrackingRepositoryProvider)
          .trackOpen(
            recipeId: widget.recipeId,
            source: widget.source,
          );
      _logger.db('AFTER | op: trackOpen | openId: ${_currentOpen?.id}');
    } catch (e, st) {
      _logger.db('ERROR | op: trackOpen | recipeId: ${widget.recipeId}', error: e, stackTrace: st);
    }
  }

  @override
  void dispose() {
    _logger.provider('RecipeDetailPage disposed | recipeId: ${widget.recipeId}');
    _trackClose();
    _pageController.dispose();
    super.dispose();
  }

  void _trackClose() {
    final open = _currentOpen;
    if (open == null) return;
    _logger.db('FIRE | op: trackClose | openId: ${open.id} | fire-and-forget from dispose');
    ref.read(recipeTrackingRepositoryProvider).trackClose(
      openId: open.id,
      openedAt: open.openedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    _logger.provider('RecipeDetailPage build() | recipeId: ${widget.recipeId} | recipeAsync.isLoading: ${recipeAsync.isLoading}');

    return Scaffold(
      backgroundColor: AkeliColors.background,
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AkeliColors.primary)),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(recipeDetailProvider(widget.recipeId)),
        ),
        data: (recipe) {
          if (recipe == null) {
            return const ErrorState(message: 'Recette introuvable.');
          }
          return _RecipeContent(
            recipe: recipe,
            currentImageIndex: _currentImageIndex,
            pageController: _pageController,
            onImageChanged: (i) {
              _logger.userAction('Recipe image swiped', screen: 'RecipeDetailPage', metadata: {'imageIndex': i});
              setState(() => _currentImageIndex = i);
            },
            onLike: () {
              _logger.userAction('Like button tapped', screen: 'RecipeDetailPage', metadata: {'recipeId': recipe.id, 'isLiked': recipe.isLiked});
              ref.read(recipeLikeProvider.notifier).toggle(recipe.id, recipe.isLiked);
            },
          );
        },
      ),
    );
  }
}

class _RecipeContent extends StatelessWidget {
  final Recipe recipe;
  final int currentImageIndex;
  final PageController pageController;
  final ValueChanged<int> onImageChanged;
  final VoidCallback onLike;

  const _RecipeContent({
    required this.recipe,
    required this.currentImageIndex,
    required this.pageController,
    required this.onImageChanged,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    appLogger.provider('RecipeContent build() | recipeId: ${recipe.id}');
    final images = recipe.imageUrls.isNotEmpty
        ? recipe.imageUrls
        : [if (recipe.thumbnailUrl != null) recipe.thumbnailUrl!];

    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HERO SECTION
              SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    if (images.isEmpty)
                      Container(
                        color: AkeliColors.background,
                        child: const Center(
                          child: Icon(Icons.restaurant_rounded, size: 80, color: AkeliColors.primary),
                        ),
                      )
                    else
                      PageView.builder(
                        controller: pageController,
                        onPageChanged: onImageChanged,
                        itemCount: images.length,
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AkeliColors.background,
                            child: const Center(
                              child: Icon(Icons.restaurant_rounded, size: 60, color: AkeliColors.primary),
                            ),
                          ),
                        ),
                      ),
                    
                    // Gradient Overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AkeliColors.onSurface.withValues(alpha: 0.8),
                              AkeliColors.onSurface.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Hero Text
                    Positioned(
                      bottom: 40,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DÉJEUNER',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AkeliColors.onPrimary.withValues(alpha: 0.8),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recipe.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AkeliColors.onPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // META CARD (Overlapping Hero)
              Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AkeliRadius.xl),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A1B1C16), blurRadius: 24, offset: Offset(0, 12)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Quick Info Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _QuickInfo(
                              icon: Icons.schedule,
                              iconColor: AkeliColors.primary,
                              label: '${recipe.totalTimeMin} min',
                            ),
                            _QuickInfo(
                              icon: Icons.trending_up,
                              iconColor: AkeliColors.accentAmber,
                              label: _difficultyLabel(recipe.difficulty),
                            ),
                            _QuickInfo(
                              icon: Icons.local_fire_department,
                              iconColor: AkeliColors.primary,
                              label: '${recipe.calories ?? 0} kcal',
                              isBold: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: AkeliColors.surfaceContainerHighest, height: 1),
                        const SizedBox(height: 24),

                        // Macros
                        Row(
                          children: [
                            Expanded(child: _MacroBox(label: 'PROTÉINES', value: '${recipe.proteinG ?? 0}g')),
                            const SizedBox(width: 12),
                            Expanded(child: _MacroBox(label: 'GLUCIDES', value: '${recipe.carbsG ?? 0}g')),
                            const SizedBox(width: 12),
                            Expanded(child: _MacroBox(label: 'LIPIDES', value: '${recipe.fatG ?? 0}g')),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tags
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _TagChip(label: 'Sans gluten'),
                            _TagChip(label: 'Riche en protéines'),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Primary Action
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                            ),
                            borderRadius: BorderRadius.circular(AkeliRadius.pill),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AkeliRadius.pill),
                              onTap: () {
                                appLogger.userAction('Add to calendar tapped', screen: 'RecipeDetailPage');
                                // TODO: Implement Add to Calendar
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: AkeliColors.onPrimary, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Ajouter au calendrier',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AkeliColors.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // DESCRIPTION SECTION
              if (recipe.description != null && recipe.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AkeliRadius.xl),
                      boxShadow: const [BoxShadow(color: Color(0x051B1C16), blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'L\'Histoire du Plat',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AkeliColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          recipe.description!,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.6,
                            color: AkeliColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // INGREDIENTS SECTION
              if (recipe.ingredients.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AkeliRadius.xl),
                      boxShadow: const [BoxShadow(color: Color(0x051B1C16), blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ingrédients',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AkeliColors.onSurface,
                              ),
                            ),
                            Text(
                              '${recipe.servings} portions',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AkeliColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ...recipe.ingredients.map(
                          (ing) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AkeliRadius.md),
                              color: Colors.transparent, 
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ing.name + (ing.isOptional ? ' (opt.)' : ''),
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: AkeliColors.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${ing.quantity.toStringAsFixed(ing.quantity % 1 == 0 ? 0 : 1)} ${ing.unit}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AkeliColors.accentAmber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // STEPS SECTION
              if (recipe.steps.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AkeliRadius.xl),
                      boxShadow: const [BoxShadow(color: Color(0x051B1C16), blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Étapes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AkeliColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...recipe.steps.map(
                          (step) => Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: AkeliColors.surfaceContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${step.stepNumber}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AkeliColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    step.instruction,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      height: 1.6,
                                      color: AkeliColors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // CREATOR CARD
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AkeliRadius.xl),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [AkeliShadows.sm],
                          image: DecorationImage(
                            image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBZoZmH1Y5a-Pc2GzIrFGmGCXlHreRhu1Z6JxT9Tc54fo417lFxPztaj8LHhnjfsKKuweQ7x2Sock9uBCk7-Mpelfn9yk-kq3cyJTZQHk8AHBjpmB4wiG-1nIt3SfGk7lpQ0anmR-m7zgit9sN0-OUMsgmx6DKQYVYYCO4zH1_AtzeaSbWnW3Yy5P3ax9SVNe5Cl1cmCc5TqlCt_uLfwIsnetSu5K9v5LG-GtLx19sLzk6rtkSnRQx9XDcIfxkvN3pSgEix_8t1c1Q'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECETTE CRÉÉE PAR',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AkeliColors.onSurfaceVariant,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chef Amina', 
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AkeliColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // TOP NAVIGATION (Fixed/Sticky)
        Positioned(
          top: topPadding + 16,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FrostedIconButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),
              _FrostedIconButton(
                icon: recipe.isLiked ? Icons.bookmark : Icons.bookmark_border,
                iconColor: recipe.isLiked ? AkeliColors.primary : AkeliColors.onSurface,
                onPressed: onLike,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _difficultyLabel(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return 'Facile';
      case 'medium':
        return 'Moyen';
      case 'hard':
        return 'Difficile';
      default:
        return d;
    }
  }
}

class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isBold;

  const _QuickInfo({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: AkeliColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MacroBox extends StatelessWidget {
  final String label;
  final String value;

  const _MacroBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AkeliColors.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AkeliColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AkeliColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FrostedIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _FrostedIconButton({
    required this.icon,
    this.iconColor = AkeliColors.onSurface,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 40,
          height: 40,
          color: AkeliColors.surfaceContainerLowest.withValues(alpha: 0.8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
