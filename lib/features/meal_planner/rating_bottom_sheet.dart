// lib/features/meal_planner/rating_bottom_sheet.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/meal_plan_provider.dart';

class RatingBottomSheet extends ConsumerStatefulWidget {
  final String mealPlanEntryId;

  const RatingBottomSheet({super.key, required this.mealPlanEntryId});

  @override
  ConsumerState<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends ConsumerState<RatingBottomSheet> {
  final _logger = appLogger;
  final _commentController = TextEditingController();

  int? _rating;
  int? _ratingTaste;
  int? _ratingEase;
  int? _ratingSatiety;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == null) return;
    _logger.userAction('Rating submit tapped', screen: 'RatingBottomSheet', metadata: {
      'mealPlanEntryId': widget.mealPlanEntryId,
      'rating': _rating,
    });
    await ref.read(ratingProvider.notifier).submitRating(
          widget.mealPlanEntryId,
          rating: _rating!,
          ratingTaste: _ratingTaste,
          ratingEase: _ratingEase,
          ratingSatiety: _ratingSatiety,
          comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
        );
    if (mounted && ref.read(ratingProvider).hasValue && !ref.read(ratingProvider).hasError) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ratingState = ref.watch(ratingProvider);
    final isLoading = ratingState.isLoading;

    ref.listen(ratingProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error.toString()),
          backgroundColor: AkeliColors.error,
        ));
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AkeliColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.ratingTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 24),
          Center(
            child: _StarRow(
              value: _rating,
              iconSize: 36,
              keyPrefix: 'overall',
              onChanged: (v) => setState(() => _rating = v),
            ),
          ),
          const SizedBox(height: 28),
          _DimensionRow(
            label: 'Goût',
            value: _ratingTaste,
            onChanged: (v) => setState(() => _ratingTaste = v),
          ),
          const SizedBox(height: 16),
          _DimensionRow(
            label: 'Facilité',
            value: _ratingEase,
            onChanged: (v) => setState(() => _ratingEase = v),
          ),
          const SizedBox(height: 16),
          _DimensionRow(
            label: 'Satiété',
            value: _ratingSatiety,
            onChanged: (v) => setState(() => _ratingSatiety = v),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Laisser un commentaire (optionnel)',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AkeliColors.textSecondary,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AkeliColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AkeliColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AkeliColors.primary),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        _logger.userAction('Rating skipped', screen: 'RatingBottomSheet');
                        Navigator.of(context).pop();
                      },
                child: Text(l10n.ratingSkip),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: (_rating == null || isLoading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AkeliColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.pill),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(l10n.ratingSubmit,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int? value;
  final double iconSize;
  final String keyPrefix;
  final ValueChanged<int> onChanged;

  const _StarRow({
    required this.value,
    required this.iconSize,
    required this.keyPrefix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= (value ?? 0);
        return GestureDetector(
          key: Key('$keyPrefix-star-$star'),
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: iconSize,
              color: filled ? AkeliColors.secondary : AkeliColors.outline,
            ),
          ),
        );
      }),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  final String label;
  final int? value;
  final ValueChanged<int> onChanged;

  const _DimensionRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AkeliColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: 12),
        _StarRow(
          value: value,
          iconSize: 22,
          keyPrefix: label.toLowerCase(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
