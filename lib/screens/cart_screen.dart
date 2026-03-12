import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/hover_tooltip.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_rounded,
                color: Color(0xFF6C63FF), size: 22),
            const SizedBox(width: 8),
            Text(
              'My Cart',
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: HoverTooltip(
                  message: cart.error != null
                      ? 'Database connection lost'
                      : 'Real-time Firebase sync active',
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_rounded,
                            size: 14,
                            color: cart.error != null
                                ? Colors.red
                                : Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          cart.error != null ? 'Offline' : 'Live',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting to smart cart...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (cartProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_off_rounded,
                          size: 56, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Connection Failed',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unable to reach Firebase database.\nCheck your internet or DB rules.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.remove_shopping_cart_rounded,
                        size: 56, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cart is Empty',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan items with your smart trolley\nto see them appear here!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Stats Header
              _buildStatsHeader(context, cartProvider),
              // Expiry warning banner
              if (cartProvider.hasExpiryWarnings)
                HoverTooltip(
                  message: 'Review expired or near-expiry items',
                  scaleOnHover: 1.02,
                  child: _buildWarningBanner(context, cartProvider),
                ),
              // Item list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return CartItemTile(item: item, index: index);
                  },
                ),
              ),
              _buildBottomBar(context, cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, CartProvider cartProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          HoverTooltip(
            message: 'Total scanned items',
            child: _statItem(Icons.inventory_2_rounded,
                '${cartProvider.itemCount}', 'Items'),
          ),
          Container(width: 1, height: 30, color: Colors.white30),
          HoverTooltip(
            message: 'Items with valid expiry',
            child: _statItem(Icons.check_circle_rounded,
                '${cartProvider.safeCount}', 'Safe'),
          ),
          Container(width: 1, height: 30, color: Colors.white30),
          HoverTooltip(
            message: 'Items expiring soon',
            child: _statItem(Icons.access_time_rounded,
                '${cartProvider.nearExpiryCount}', 'Near'),
          ),
          Container(width: 1, height: 30, color: Colors.white30),
          HoverTooltip(
            message: 'Items past expiry date',
            child: _statItem(Icons.warning_amber_rounded,
                '${cartProvider.expiredCount}', 'Expired'),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildWarningBanner(
      BuildContext context, CartProvider cartProvider) {
    final expCount = cartProvider.expiredCount;
    final nearCount = cartProvider.nearExpiryCount;
    final parts = <String>[];
    if (expCount > 0) parts.add('$expCount expired');
    if (nearCount > 0) parts.add('$nearCount expiring soon');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 20, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠ ${parts.join(' & ')} item${(expCount + nearCount) > 1 ? 's' : ''} in cart',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.white54),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.orbitron(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
            const Spacer(),
            HoverTooltip(
              message: 'Proceed to checkout',
              scaleOnHover: 1.05,
              child: FilledButton.icon(
                onPressed: cartProvider.items.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        );
                      },
                icon: const Icon(Icons.shopping_bag_rounded),
                label: const Text(
                  'Checkout',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
