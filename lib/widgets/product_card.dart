import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../utils/app_theme.dart';
import '../utils/expiry_utils.dart';
import 'glass_container.dart';
import 'suggestions_row.dart';

class ProductCard extends StatelessWidget {
  final CartItem item;
  final bool busy;
  final bool isRecent;
  final bool loadingSuggestions;
  final List<CartItem> suggestions;
  final VoidCallback onTapCard;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final ValueChanged<CartItem> onTapSuggestion;

  const ProductCard({
    super.key,
    required this.item,
    required this.busy,
    required this.isRecent,
    required this.loadingSuggestions,
    required this.suggestions,
    required this.onTapCard,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    required this.onTapSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final status = ExpiryUtils.getExpiryStatus(item.expiry);
    final bool isExpired = status == ExpiryStatus.expired;
    final bool isNear = status == ExpiryStatus.nearExpiry;

    Color accent = AppTheme.accentPurple;
    if (isExpired) {
      accent = AppTheme.errorRed;
    } else if (isNear) {
      accent = Colors.orangeAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        opacity: isRecent ? 0.12 : 0.05,
        borderColor: isRecent ? AppTheme.accentPurpleLight : AppTheme.glassBorder,
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTapCard,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _ProductImage(imageUrl: item.imageUrl),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.title(context),
                                ),
                              ),
                              if (isRecent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentPurple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'ADDED',
                                    style: AppTheme.body(context).copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${item.price.toStringAsFixed(2)}',
                            style: AppTheme.price(context).copyWith(
                              color: AppTheme.accentPurpleLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Expiry: ${item.expiry.isEmpty ? 'N/A' : item.expiry}',
                            style: AppTheme.body(context).copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          _ExpiryBadge(status: status, accent: accent),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        _quantityAction(
                          icon: Icons.add_rounded,
                          onPressed: busy ? null : onIncrement,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${item.quantity}',
                            style: AppTheme.title(context),
                          ),
                        ),
                        _quantityAction(
                          icon: Icons.remove_rounded,
                          onPressed: busy ? null : onDecrement,
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: busy ? null : onDelete,
                          icon: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_outline_rounded),
                          color: AppTheme.errorRed,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (loadingSuggestions)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (suggestions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: AppTheme.glassBorder, height: 24),
                      Text(
                        "You may also like",
                        style: AppTheme.body(context).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SuggestionsRow(
                        suggestions: suggestions,
                        onTapSuggestion: onTapSuggestion,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quantityAction({required IconData icon, required VoidCallback? onPressed}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, color: AppTheme.textMain, size: 18),
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final ExpiryStatus status;
  final Color accent;

  const _ExpiryBadge({required this.status, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        ExpiryUtils.getStatusText(status),
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return _placeholder();
    }

    return Image.network(
      imageUrl,
      width: 80,
      height: 80,
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
      width: 80,
      height: 80,
      color: AppTheme.glassBackground,
      child: const Icon(Icons.image_not_supported_rounded, color: AppTheme.textMuted),
    );
  }
}
