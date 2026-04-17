import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../utils/app_theme.dart';
import 'glass_container.dart';

class SuggestionsRow extends StatelessWidget {
  final List<CartItem> suggestions;
  final ValueChanged<CartItem> onTapSuggestion;

  const SuggestionsRow({
    super.key,
    required this.suggestions,
    required this.onTapSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final suggestion = suggestions[index];
          return _SuggestionCard(
            suggestion: suggestion,
            onTap: () => onTapSuggestion(suggestion),
          );
        },
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final CartItem suggestion;
  final VoidCallback onTap;

  const _SuggestionCard({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(6),
      width: 200,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _SuggestionImage(imageUrl: suggestion.imageUrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(context).copyWith(
                      color: AppTheme.textMain,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${suggestion.price.toStringAsFixed(2)}',
                    style: AppTheme.price(context).copyWith(
                      color: AppTheme.accentPurpleLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.accentPurpleLight,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionImage extends StatelessWidget {
  final String imageUrl;

  const _SuggestionImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return _placeholder();
    }

    return Image.network(
      imageUrl,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      frameBuilder: (_, child, frame, __) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: frame == null ? 0 : 1,
          child: child,
        );
      },
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return _placeholder();
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppTheme.glassBackground,
      child: const Icon(Icons.image_not_supported_rounded, color: AppTheme.textMuted, size: 20),
    );
  }
}
