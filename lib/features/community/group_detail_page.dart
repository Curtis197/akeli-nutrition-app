import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/widgets/section_header.dart';
import 'package:akeli/shared/widgets/avatar.dart';
import 'package:akeli/shared/widgets/akeli_recipe_card.dart';

class GroupDetailPage extends StatelessWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    const members = ['AB', 'CD', 'EF', 'GH', 'IJ'];
    const recipes = [
      ('Salade César', 320, 4.5),
      ('Poulet Tikka', 450, 4.8),
      ('Smoothie Vert', 180, 4.2),
    ];

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Détail du groupe'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              color: AkeliColors.primary.withValues(alpha: 0.1),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🥗', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text('Groupe Santé', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AkeliSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Un groupe dédié à une alimentation saine et équilibrée.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AkeliColors.textSecondary)),
                  const SizedBox(height: AkeliSpacing.lg),
                  AkeliSectionHeader(
                    title: 'Membres',
                    trailingLabel: 'Inviter',
                    onTrailingTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inviter un ami')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: members.map((initials) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AkeliAvatar(initials: initials, size: AvatarSize.md),
                        const SizedBox(height: 4),
                        Text(initials, style: Theme.of(context).textTheme.labelSmall),
                      ],
                    )).toList(),
                  ),
                  const SizedBox(height: AkeliSpacing.lg),
                  const AkeliSectionHeader(title: 'Recettes partagées'),
                  const SizedBox(height: 12),
                  ...recipes.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AkeliRecipeCard(
                      title: r.$1,
                      calories: r.$2,
                      rating: r.$3,
                      likes: 12,
                      comments: 3,
                      saves: 5,
                      tags: const [],
                      hasImage: false,
                    ),
                  )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
