import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cart_item_model.dart';

class SuggestionStrip extends StatelessWidget {
  final List<CartItem> suggestions;
  final ValueChanged<CartItem> onTapSuggestion;

  const SuggestionStrip({
    super.key,
    required this.suggestions,
    required this.onTapSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You might also need',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final suggestion = suggestions[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTapSuggestion(suggestion),
                child: Container(
                  width: 170,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _SuggestionImage(imageUrl: suggestion.imageUrl),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs ${suggestion.price.toStringAsFixed(2)}',
                              style: GoogleFonts.orbitron(
                                color: const Color(0xFF8E89FF),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.add_circle_rounded,
                        color: Color(0xFF8E89FF),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      frameBuilder: (_, child, frame, __) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
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
      width: 52,
      height: 52,
      color: const Color(0xFF22253B),
      child: const Icon(Icons.image_not_supported_rounded, color: Colors.white38),
    );
  }
}
