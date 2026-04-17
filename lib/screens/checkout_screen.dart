import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../services/stripe_checkout_service.dart';
import '../utils/app_theme.dart';
import '../utils/expiry_utils.dart';
import '../widgets/glass_container.dart';
import '../widgets/price_summary.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;
  final StripeCheckoutService _stripeCheckoutService = StripeCheckoutService();

  Future<void> _handleCheckout(CartProvider provider) async {
    setState(() => _isProcessing = true);
    try {
      final checkoutUrl = await _stripeCheckoutService.createCheckoutSession(
        items: provider.items,
        trolleyId: provider.trolleyId,
        currency: 'inr',
      );

      final launched = await launchUrl(
        Uri.parse(checkoutUrl),
        mode: LaunchMode.platformDefault,
      );

      if (!launched) {
        throw StateError('Could not open Stripe Checkout. Please try again.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.accentPurple,
          content: Row(
            children: const [
              Icon(Icons.lock_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Stripe checkout opened. Complete payment to finalize your order.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      setState(() => _isProcessing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.errorRed,
          content: Text('Checkout failed: $e', style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final bool hasExpiredItems = cartProvider.hasExpiredItems;

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Text('Secure Checkout', style: AppTheme.heading(context).copyWith(fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textMain),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainBackgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentPurple.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 36),
                          const SizedBox(height: 12),
                          Text(
                            'Order Summary',
                            style: AppTheme.heading(context).copyWith(fontSize: 22, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${cartProvider.totalItems} unit${cartProvider.totalItems == 1 ? '' : 's'} ready for payment',
                            style: AppTheme.body(context).copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Items Overview",
                      style: AppTheme.title(context).copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    ...cartProvider.items.map((item) {
                      final status = ExpiryUtils.getExpiryStatus(item.expiry);
                      final isExpired = status == ExpiryStatus.expired;
                      final borderColor = isExpired ? AppTheme.errorRed : AppTheme.glassBorder;
                      final accentColor = isExpired ? AppTheme.errorRed : AppTheme.accentPurple;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          borderColor: borderColor,
                          child: Row(
                            children: [
                              _CheckoutImage(imageUrl: item.imageUrl),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTheme.title(context).copyWith(fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${item.quantity}  •  Exp: ${item.expiry}',
                                      style: AppTheme.body(context).copyWith(fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        ExpiryUtils.getStatusText(status),
                                        style: TextStyle(
                                          color: accentColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                                style: AppTheme.price(context).copyWith(color: AppTheme.accentPurpleLight),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    PriceSummary(
                      subtotal: cartProvider.subtotal,
                      tax: cartProvider.tax,
                      total: cartProvider.total,
                    ),
                    if (hasExpiredItems) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Checkout is blocked. Please remove expired items from the cart first.',
                                style: AppTheme.body(context).copyWith(
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GlassContainer(
                borderRadius: 0,
                opacity: 0.1,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: SizedBox(
                  width: double.infinity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (!hasExpiredItems)
                          BoxShadow(
                            color: AppTheme.accentPurple.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing || hasExpiredItems
                          ? null
                          : () => _handleCheckout(cartProvider),
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.verified_user_outlined, size: 22, color: Colors.white),
                      label: Text(
                        _isProcessing ? 'Opening Stripe Checkout...' : 'Pay Securely with Stripe',
                        style: AppTheme.title(context).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasExpiredItems ? AppTheme.glassBorder : AppTheme.accentPurple,
                        disabledBackgroundColor: AppTheme.glassBorder,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutImage extends StatelessWidget {
  final String imageUrl;

  const _CheckoutImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        frameBuilder: (_, child, frame, __) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: frame == null ? 0 : 1,
            child: child,
          );
        },
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _placeholder();
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image_not_supported_rounded, color: AppTheme.textMuted),
    );
  }
}
