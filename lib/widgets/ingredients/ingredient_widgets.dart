import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../models/multimedia_models.dart';

/// Widget to display an ingredient with optional image
class IngredientListTile extends StatelessWidget {
  final Ingredient ingredient;
  final String langCode;
  final double imageSize;
  final VoidCallback? onTap;

  const IngredientListTile({
    super.key,
    required this.ingredient,
    required this.langCode,
    this.imageSize = 60.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = ingredient.getName(langCode);

    return ListTile(
      onTap: onTap,
      leading: _buildImage(),
      title: Text(
        name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: ingredient.description != null
          ? Text(
              ingredient.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            )
          : null,
      isThreeLine: ingredient.description != null,
    );
  }

  Widget _buildImage() {
    if (ingredient.imageUrl == null) {
      // Placeholder icon when no image
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.restaurant,
          color: Colors.grey.shade400,
          size: imageSize * 0.5,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: ingredient.imageThumbnailUrl ?? ingredient.imageUrl!,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: imageSize,
          height: imageSize,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: imageSize,
          height: imageSize,
          color: Colors.grey.shade200,
          child: Icon(
            Icons.broken_image,
            color: Colors.grey.shade400,
            size: imageSize * 0.5,
          ),
        ),
      ),
    );
  }
}

/// Grid view of ingredients with images
class IngredientGrid extends StatelessWidget {
  final List<Ingredient> ingredients;
  final String langCode;
  final int crossAxisCount;
  final double imageSize;
  final Function(Ingredient)? onIngredientTap;

  const IngredientGrid({
    super.key,
    required this.ingredients,
    required this.langCode,
    this.crossAxisCount = 3,
    this.imageSize = 80.0,
    this.onIngredientTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        return _IngredientGridItem(
          ingredient: ingredient,
          langCode: langCode,
          imageSize: imageSize,
          onTap: onIngredientTap != null
              ? () => onIngredientTap!(ingredient)
              : null,
        );
      },
    );
  }
}

class _IngredientGridItem extends StatelessWidget {
  final Ingredient ingredient;
  final String langCode;
  final double imageSize;
  final VoidCallback? onTap;

  const _IngredientGridItem({
    required this.ingredient,
    required this.langCode,
    required this.imageSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = ingredient.getName(langCode);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ingredient.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ingredient.imageThumbnailUrl ?? ingredient.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.restaurant,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.grey.shade400,
                        size: imageSize * 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
