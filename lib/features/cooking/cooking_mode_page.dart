import 'dart:async';

import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/features/recipes/widgets/ingredient_detail_sheet.dart';
import 'package:akeli/shared/models/recipe.dart';
import 'package:akeli/shared/widgets/recipe_video_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class CookingModePage extends StatefulWidget {
  final Recipe recipe;
  final int initialStepIndex;

  const CookingModePage({
    super.key,
    required this.recipe,
    this.initialStepIndex = 0,
  });

  @override
  State<CookingModePage> createState() => _CookingModePageState();
}

class _CookingModePageState extends State<CookingModePage> {
  final _logger = appLogger;
  late int _currentStepIndex;
  int _timerSeconds = 0;
  bool _timerRunning = false;
  Timer? _timer;
  final Set<String> _checkedIngredients = {};
  bool _infoOpen = false;

  RecipeStep get _currentStep =>
      widget.recipe.steps[_currentStepIndex];

  List<RecipeIngredient> get _stepIngredients {
    if (_currentStep.ingredientIds.isNotEmpty) {
      return widget.recipe.ingredients
          .where((i) =>
              _currentStep.ingredientIds.contains(i.ingredientId))
          .toList();
    }
    return widget.recipe.ingredients;
  }

  @override
  void initState() {
    super.initState();
    if (widget.recipe.steps.isEmpty) {
      _currentStepIndex = 0;
      _timerSeconds = 0;
      _logger.provider('CookingModePage initState() | recipeId: ${widget.recipe.id} | no steps');
      return;
    }
    _currentStepIndex = widget.initialStepIndex
        .clamp(0, widget.recipe.steps.length - 1);
    _resetTimer();
    _logger.provider(
        'CookingModePage initState() | recipeId: ${widget.recipe.id} | initialStep: $_currentStepIndex');
  }

  void _resetTimer() {
    _timer?.cancel();
    _timerRunning = false;
    _timerSeconds = (_currentStep.durationMin ?? 0) * 60;
  }

  void _toggleTimer() {
    if (_timerRunning) {
      _timer?.cancel();
      _logger.userAction('Timer paused', screen: 'CookingModePage',
          metadata: {'step': _currentStepIndex + 1, 'remaining': _timerSeconds});
      setState(() => _timerRunning = false);
    } else {
      _logger.userAction('Timer started', screen: 'CookingModePage',
          metadata: {'step': _currentStepIndex + 1, 'totalSeconds': _timerSeconds});
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!_timerRunning) { t.cancel(); return; }
        if (_timerSeconds <= 0) {
          t.cancel();
          HapticFeedback.mediumImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Étape terminée !'),
              backgroundColor: AkeliColors.primary,
            ));
            setState(() {
              _timerRunning = false;
              _timerSeconds = (_currentStep.durationMin ?? 0) * 60;
            });
          }
        } else {
          if (mounted) setState(() => _timerSeconds--);
        }
      });
      setState(() => _timerRunning = true);
    }
  }

  void _goToStep(int index) {
    if (index < 0 || index >= widget.recipe.steps.length) return;
    _logger.userAction('Step navigation', screen: 'CookingModePage',
        metadata: {'from': _currentStepIndex + 1, 'to': index + 1});
    setState(() {
      _currentStepIndex = index;
      _infoOpen = false;
      _resetTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logger.provider(
        'CookingModePage disposed | recipeId: ${widget.recipe.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recipe.steps.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
              ),
              const Expanded(
                child: Center(child: Text('Aucune étape disponible')),
              ),
            ],
          ),
        ),
      );
    }
    final step = _currentStep;
    final totalSteps = widget.recipe.steps.length;
    final isLast = _currentStepIndex == totalSteps - 1;

    return Scaffold(
      backgroundColor: AkeliColors.background,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < -300) {
              _goToStep(_currentStepIndex + 1);
            } else if ((details.primaryVelocity ?? 0) > 300) {
              _goToStep(_currentStepIndex - 1);
            }
          },
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return _LandscapeBody(
                  recipe: widget.recipe,
                  currentStepIndex: _currentStepIndex,
                  timerSeconds: _timerSeconds,
                  timerRunning: _timerRunning,
                  infoOpen: _infoOpen,
                  checkedIngredients: _checkedIngredients,
                  stepIngredients: _stepIngredients,
                  onClose: () {
                    _logger.userAction('Cooking mode closed',
                        screen: 'CookingModePage',
                        metadata: {'atStep': _currentStepIndex + 1});
                    context.pop();
                  },
                  onTimerToggle: _toggleTimer,
                  onPrev: () => _goToStep(_currentStepIndex - 1),
                  onNext: isLast
                      ? () {
                          _logger.userAction('Cooking mode completed',
                              screen: 'CookingModePage',
                              metadata: {'recipeId': widget.recipe.id});
                          context.pop();
                        }
                      : () => _goToStep(_currentStepIndex + 1),
                  onInfoToggle: () => setState(() => _infoOpen = !_infoOpen),
                  onIngredientTap: (ing) =>
                      IngredientDetailSheet.show(context, ing),
                  onIngredientLongPress: (ing) {
                    _logger.userAction('Ingredient checked',
                        screen: 'CookingModePage',
                        metadata: {'ingredientId': ing.ingredientId});
                    setState(() {
                      if (_checkedIngredients.contains(ing.ingredientId)) {
                        _checkedIngredients.remove(ing.ingredientId);
                      } else {
                        _checkedIngredients.add(ing.ingredientId);
                      }
                    });
                  },
                );
              }
              // ── portrait (unchanged) ─────────────────────────────────────────
              return Column(
                children: [
                  _TopBar(
                    current: _currentStepIndex + 1,
                    total: totalSteps,
                    onClose: () {
                      _logger.userAction('Cooking mode closed',
                          screen: 'CookingModePage',
                          metadata: {'atStep': _currentStepIndex + 1});
                      context.pop();
                    },
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Center(
                        child: Text(
                          step.instruction,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            height: 1.5,
                            color: AkeliColors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (step.videoUrl != null || step.imageUrl != null)
                    Flexible(
                      flex: 3,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AkeliRadius.xl),
                          child: step.videoUrl != null
                              ? RecipeVideoCard(
                                  videoUrl: step.videoUrl!,
                                  thumbnailUrl: step.imageUrl)
                              : CachedNetworkImage(
                                  imageUrl: step.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity),
                        ),
                      ),
                    ),
                  if (step.durationMin != null)
                    _TimerWidget(
                      totalSeconds: step.durationMin! * 60,
                      remainingSeconds: _timerSeconds,
                      isRunning: _timerRunning,
                      onToggle: _toggleTimer,
                    ),
                  if (_stepIngredients.isNotEmpty)
                    _IngredientStrip(
                      ingredients: _stepIngredients,
                      checked: _checkedIngredients,
                      onTap: (ing) =>
                          IngredientDetailSheet.show(context, ing),
                      onLongPress: (ing) {
                        _logger.userAction('Ingredient checked',
                            screen: 'CookingModePage',
                            metadata: {'ingredientId': ing.ingredientId});
                        setState(() {
                          if (_checkedIngredients
                              .contains(ing.ingredientId)) {
                            _checkedIngredients
                                .remove(ing.ingredientId);
                          } else {
                            _checkedIngredients
                                .add(ing.ingredientId);
                          }
                        });
                      },
                    ),
                  _NavButtons(
                    isFirst: _currentStepIndex == 0,
                    isLast: isLast,
                    onPrev: () => _goToStep(_currentStepIndex - 1),
                    onNext: isLast
                        ? () {
                            _logger.userAction('Cooking mode completed',
                                screen: 'CookingModePage',
                                metadata: {'recipeId': widget.recipe.id});
                            context.pop();
                          }
                        : () => _goToStep(_currentStepIndex + 1),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onClose;

  const _TopBar(
      {required this.current,
      required this.total,
      required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Étape $current / $total',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AkeliColors.onSurface),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: current / total,
                backgroundColor: AkeliColors.surfaceContainerHigh,
                color: AkeliColors.primary,
                minHeight: 6,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AkeliColors.onSurface),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _TimerWidget extends StatelessWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final VoidCallback onToggle;

  const _TimerWidget({
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.isRunning,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final progress =
        totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;

    return GestureDetector(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: CircularPercentIndicator(
          radius: 44,
          lineWidth: 6,
          percent: progress.clamp(0.0, 1.0),
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AkeliColors.onSurface),
              ),
              Icon(
                isRunning
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: AkeliColors.primary,
                size: 20,
              ),
            ],
          ),
          progressColor: AkeliColors.primary,
          backgroundColor: AkeliColors.surfaceContainerHigh,
        ),
      ),
    );
  }
}

class _IngredientStrip extends StatelessWidget {
  final List<RecipeIngredient> ingredients;
  final Set<String> checked;
  final ValueChanged<RecipeIngredient> onTap;
  final ValueChanged<RecipeIngredient> onLongPress;

  const _IngredientStrip({
    required this.ingredients,
    required this.checked,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: ingredients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final ing = ingredients[i];
          final isChecked = checked.contains(ing.ingredientId);
          return GestureDetector(
            onTap: () => onTap(ing),
            onLongPress: () => onLongPress(ing),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isChecked
                    ? AkeliColors.surfaceContainer
                    : AkeliColors.surfaceContainerLow,
                borderRadius:
                    BorderRadius.circular(AkeliRadius.pill),
                border: Border.all(
                    color: isChecked
                        ? AkeliColors.outline
                        : Colors.transparent),
              ),
              child: Text(
                ing.name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isChecked
                      ? AkeliColors.onSurfaceVariant
                      : AkeliColors.onSurface,
                  decoration: isChecked
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavButtons extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavButtons({
    required this.isFirst,
    required this.isLast,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isFirst ? null : onPrev,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                    color: isFirst
                        ? AkeliColors.outline.withValues(alpha: 0.3)
                        : AkeliColors.outline),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AkeliRadius.lg)),
              ),
              child: Text(
                'Précédent',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: isFirst
                        ? AkeliColors.outline
                        : AkeliColors.onSurface),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AkeliColors.primary,
                foregroundColor: AkeliColors.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AkeliRadius.lg)),
              ),
              child: Text(
                isLast ? 'Terminer' : 'Suivant',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final int remainingSeconds;
  final bool isRunning;
  final VoidCallback onToggle;

  const _TimerPill({
    required this.remainingSeconds,
    required this.isRunning,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined,
                size: 14, color: AkeliColors.primary),
            const SizedBox(width: 4),
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AkeliColors.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 14,
              color: AkeliColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LandscapeInfoPanel extends StatelessWidget {
  final String instruction;
  final List<RecipeIngredient> ingredients;
  final Set<String> checked;
  final ValueChanged<RecipeIngredient> onTap;
  final ValueChanged<RecipeIngredient> onLongPress;

  const _LandscapeInfoPanel({
    required this.instruction,
    required this.ingredients,
    required this.checked,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AkeliRadius.xl),
          bottomLeft: Radius.circular(AkeliRadius.xl),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              instruction,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.5,
                color: AkeliColors.onSurface,
              ),
            ),
            if (ingredients.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(
                color: AkeliColors.outline.withValues(alpha: 0.3),
                height: 1,
              ),
              const SizedBox(height: 10),
              ...ingredients.map((ing) {
                final isChecked = checked.contains(ing.ingredientId);
                return GestureDetector(
                  onTap: () => onTap(ing),
                  onLongPress: () => onLongPress(ing),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isChecked
                                ? AkeliColors.outline
                                : AkeliColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${ing.name}  ${ing.quantity.toStringAsFixed((ing.quantity - ing.quantity.truncate()).abs() < 0.001 ? 0 : 1)} ${ing.unit}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isChecked
                                  ? AkeliColors.onSurfaceVariant
                                  : AkeliColors.onSurface,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _LandscapeMediaCenter extends StatelessWidget {
  final RecipeStep step;
  final int? remainingSeconds;
  final bool timerRunning;
  final VoidCallback onTimerToggle;

  const _LandscapeMediaCenter({
    required this.step,
    this.remainingSeconds,
    required this.timerRunning,
    required this.onTimerToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AkeliRadius.xl),
      child: Stack(
        fit: StackFit.expand,
        children: [
          step.videoUrl != null
              ? RecipeVideoCard(
                  videoUrl: step.videoUrl!,
                  thumbnailUrl: step.imageUrl)
              : CachedNetworkImage(
                  imageUrl: step.imageUrl!,
                  fit: BoxFit.cover),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                  colors: [Colors.transparent, Colors.transparent, Colors.black87],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 40, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      step.instruction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        height: 1.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (remainingSeconds != null) ...[
                    const SizedBox(width: 8),
                    _TimerPill(
                      remainingSeconds: remainingSeconds!,
                      isRunning: timerRunning,
                      onToggle: onTimerToggle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandscapeCenter extends StatelessWidget {
  final RecipeStep step;
  final List<RecipeIngredient> stepIngredients;
  final Set<String> checked;
  final int timerSeconds;
  final bool timerRunning;
  final bool infoOpen;
  final VoidCallback onTimerToggle;
  final ValueChanged<RecipeIngredient> onIngredientTap;
  final ValueChanged<RecipeIngredient> onIngredientLongPress;

  const _LandscapeCenter({
    required this.step,
    required this.stepIngredients,
    required this.checked,
    required this.timerSeconds,
    required this.timerRunning,
    required this.infoOpen,
    required this.onTimerToggle,
    required this.onIngredientTap,
    required this.onIngredientLongPress,
  });

  bool get _hasMedia => step.videoUrl != null || step.imageUrl != null;

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.of(context).size.width * 0.38;

    final center = _hasMedia
        ? _LandscapeMediaCenter(
            step: step,
            remainingSeconds: step.durationMin != null ? timerSeconds : null,
            timerRunning: timerRunning,
            onTimerToggle: onTimerToggle,
          )
        : _LandscapeTextCenter(
            instruction: step.instruction,
            remainingSeconds: step.durationMin != null ? timerSeconds : null,
            timerRunning: timerRunning,
            onTimerToggle: onTimerToggle,
          );

    return Stack(
      children: [
        Positioned.fill(child: center),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          top: 0,
          bottom: 0,
          right: 0,
          width: infoOpen ? panelWidth : 0,
          child: ClipRect(
            child: OverflowBox(
              maxWidth: panelWidth,
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: infoOpen ? 1.0 : 0.0,
                child: SizedBox(
                  width: panelWidth,
                  child: _LandscapeInfoPanel(
                    instruction: step.instruction,
                    ingredients: stepIngredients,
                    checked: checked,
                    onTap: onIngredientTap,
                    onLongPress: onIngredientLongPress,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LandscapeTextCenter extends StatelessWidget {
  final String instruction;
  final int? remainingSeconds;
  final bool timerRunning;
  final VoidCallback onTimerToggle;

  const _LandscapeTextCenter({
    required this.instruction,
    this.remainingSeconds,
    required this.timerRunning,
    required this.onTimerToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AkeliRadius.xl),
      child: ColoredBox(
        color: AkeliColors.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  instruction,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    height: 1.5,
                    color: AkeliColors.onSurface,
                  ),
                ),
              ),
              if (remainingSeconds != null) ...[
                const SizedBox(height: 10),
                _TimerPill(
                  remainingSeconds: remainingSeconds!,
                  isRunning: timerRunning,
                  onToggle: onTimerToggle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool enabled;

  const _SideNavIcon({
    required this.icon,
    required this.onTap,
    required this.filled,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? AkeliColors.primary
              : AkeliColors.surfaceContainerHigh
                  .withValues(alpha: enabled ? 1.0 : 0.3),
        ),
        child: Icon(
          icon,
          color: filled
              ? AkeliColors.onPrimary
              : AkeliColors.onSurface
                  .withValues(alpha: enabled ? 1.0 : 0.3),
          size: 22,
        ),
      ),
    );
  }
}

class _LandscapeBody extends StatelessWidget {
  final Recipe recipe;
  final int currentStepIndex;
  final int timerSeconds;
  final bool timerRunning;
  final bool infoOpen;
  final Set<String> checkedIngredients;
  final List<RecipeIngredient> stepIngredients;
  final VoidCallback onClose;
  final VoidCallback onTimerToggle;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onInfoToggle;
  final ValueChanged<RecipeIngredient> onIngredientTap;
  final ValueChanged<RecipeIngredient> onIngredientLongPress;

  const _LandscapeBody({
    required this.recipe,
    required this.currentStepIndex,
    required this.timerSeconds,
    required this.timerRunning,
    required this.infoOpen,
    required this.checkedIngredients,
    required this.stepIngredients,
    required this.onClose,
    required this.onTimerToggle,
    required this.onPrev,
    required this.onNext,
    required this.onInfoToggle,
    required this.onIngredientTap,
    required this.onIngredientLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final totalSteps = recipe.steps.length;
    final isFirst = currentStepIndex == 0;
    final isLast = currentStepIndex == totalSteps - 1;
    final step = recipe.steps[currentStepIndex];
    final hasIngredients = stepIngredients.isNotEmpty;

    return Column(
      children: [
        _TopBar(
          current: currentStepIndex + 1,
          total: totalSteps,
          onClose: onClose,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                _SideNavIcon(
                  icon: Icons.chevron_left_rounded,
                  onTap: onPrev,
                  filled: false,
                  enabled: !isFirst,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _LandscapeCenter(
                    step: step,
                    stepIngredients: stepIngredients,
                    checked: checkedIngredients,
                    timerSeconds: timerSeconds,
                    timerRunning: timerRunning,
                    infoOpen: infoOpen,
                    onTimerToggle: onTimerToggle,
                    onIngredientTap: onIngredientTap,
                    onIngredientLongPress: onIngredientLongPress,
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SideNavIcon(
                      icon: isLast
                          ? Icons.check_rounded
                          : Icons.chevron_right_rounded,
                      onTap: onNext,
                      filled: true,
                      enabled: true,
                    ),
                    if (hasIngredients) ...[
                      const SizedBox(height: 8),
                      _SideNavIcon(
                        icon: Icons.info_outline_rounded,
                        onTap: onInfoToggle,
                        filled: infoOpen,
                        enabled: true,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
