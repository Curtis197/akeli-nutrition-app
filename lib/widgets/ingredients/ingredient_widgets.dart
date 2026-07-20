import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/logger.dart';
import '../../models/multimedia_models.dart';

final _logger = appLogger;

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
    final name = ingredient.getName(langCode);

    return ListTile(
      onTap: () {
        _logger.userAction('Ingredient tapped: $name', screen: 'IngredientListTile');
        onTap?.call();
      },
      leading: _buildImage(),
      title: Text(name),
      subtitle: ingredient.description != null ? Text(ingredient.description!) : null,
    );
  }

  Widget _buildImage() {
    if (ingredient.imageThumbnailUrl != null || ingredient.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: ingredient.imageThumbnailUrl ?? ingredient.imageUrl!,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.restaurant, color: Colors.grey),
    );
  }
}

/// Grid display of ingredients
class IngredientGrid extends StatelessWidget {
  final List<Ingredient> ingredients;
  final String langCode;
  final Function(Ingredient)? onIngredientTap;

  const IngredientGrid({
    super.key,
    required this.ingredients,
    required this.langCode,
    this.onIngredientTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        final name = ingredient.getName(langCode);
        return GestureDetector(
          onTap: () {
            _logger.userAction('Ingredient tapped: $name', screen: 'IngredientGrid');
            onIngredientTap?.call(ingredient);
          },
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ingredient.imageThumbnailUrl != null || ingredient.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: ingredient.imageThumbnailUrl ?? ingredient.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, __) => Container(color: Colors.grey.shade200),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.restaurant, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
