import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../utils/expiry_utils.dart';
import '../widgets/hover_tooltip.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _pendingItemIds = <String>{};
  bool _isClearing = false;

  Future<void> _runItemAction(
    String itemId,
    Future<void> Function() action,
  ) async {
    if (_pendingItemIds.contains(itemId)) return;

    setState(() {
      _pendingItemIds.add(itemId);
    });

    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _pendingItemIds.remove(itemId);
      });
    }
  }

  Future<void> _confirmClearCart(CartProvider provider) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: const Text('Clear cart?'),
          content: const Text('This will remove all items from your cart.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isClearing = true);
    try {
      await provider.clearCart();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Clear cart failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

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
            const Icon(
              Icons.shopping_cart_rounded,
              color: Color(0xFF6C63FF),
              size: 22,
            ),
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
            builder: (_, cart, __) {
              final bool disabled =
                  _isClearing || cart.isLoading || cart.items.isEmpty;
              return IconButton(
                tooltip: 'Clear cart',
                onPressed: disabled ? null : () => _confirmClearCart(cart),
                icon: _isClearing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.redAccent,
                      ),
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (_, cart, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: HoverTooltip(
                  message: cart.error != null
                      ? 'Database connection lost'
                      : 'Real-time Firebase sync active',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_rounded,
                          size: 14,
                          color: cart.error != null ? Colors.red : Colors.green,
                        ),
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
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 56,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Connection Failed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unable to reach Firebase database. Check your internet or DB rules.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: cartProvider.retryConnection,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
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
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove_shopping_cart_rounded,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cart is Empty',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan items with your smart trolley to see them appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildStatsHeader(context, cartProvider),
              if (cartProvider.hasExpiryWarnings)
                HoverTooltip(
                  message: 'Review expired or near-expiry items',
                  scaleOnHover: 1.02,
                  child: _buildWarningBanner(cartProvider),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    final bool busy = _pendingItemIds.contains(item.id);

                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) async => !busy,
                      onDismissed: (_) {
                        _runItemAction(
                          item.id,
                          () => cartProvider.removeItem(item.id),
                        );
                      },
                      child: _buildCartItemCard(
                        item: item,
                        busy: busy,
                        onDecrement: () => _runItemAction(
                          item.id,
                          () => cartProvider.decrementItem(item.id),
                        ),
                        onIncrement: () => _runItemAction(
                          item.id,
                          () => cartProvider.addOrIncrementItem(
                            itemId: item.id,
                            name: item.name,
                            price: item.price,
                            expiry: item.expiry,
                          ),
                        ),
                        onDelete: () => _runItemAction(
                          item.id,
                          () => cartProvider.removeItem(item.id),
                        ),
                      ),
                    );
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
          _statItem(
            Icons.inventory_2_rounded,
            '${cartProvider.totalItems}',
            'Items',
          ),
          Container(width: 1, height: 30, color: Colors.white30),
          _statItem(
            Icons.check_circle_rounded,
            '${cartProvider.safeCount}',
            'Safe',
          ),
          Container(width: 1, height: 30, color: Colors.white30),
          _statItem(
            Icons.access_time_rounded,
            '${cartProvider.nearExpiryCount}',
            'Near',
          ),
          Container(width: 1, height: 30, color: Colors.white30),
          _statItem(
            Icons.warning_amber_rounded,
            '${cartProvider.expiredCount}',
            'Expired',
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

  Widget _buildWarningBanner(CartProvider cartProvider) {
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
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${parts.join(' & ')} item${(expCount + nearCount) > 1 ? 's' : ''} in cart',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cartProvider) {
    final bool checkoutDisabled =
        cartProvider.items.isEmpty ||
        cartProvider.hasExpiredItems ||
        _isClearing;

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
                  'Subtotal: Rs ${cartProvider.subtotal.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
                Text(
                  'Tax: Rs ${cartProvider.tax.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total: Rs ${cartProvider.total.toStringAsFixed(2)}',
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (cartProvider.hasExpiredItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Remove expired items to checkout',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                HoverTooltip(
                  message: cartProvider.hasExpiredItems
                      ? 'Checkout disabled due to expired items'
                      : 'Proceed to checkout',
                  scaleOnHover: 1.05,
                  child: FilledButton.icon(
                    onPressed: checkoutDisabled
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard({
    required CartItem item,
    required bool busy,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required VoidCallback onDelete,
  }) {
    final status = ExpiryUtils.getExpiryStatus(item.expiry);
    final statusColor = ExpiryUtils.getStatusColor(status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${item.id} | Exp: ${item.expiry}',
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: busy ? null : onDecrement,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: Colors.white70,
                      tooltip: 'Decrease quantity',
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Text(
                        '${item.quantity}',
                        key: ValueKey('${item.id}-${item.quantity}'),
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: busy ? null : onIncrement,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: const Color(0xFF6C63FF),
                      tooltip: 'Increase quantity',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs ${(item.price * item.quantity).toStringAsFixed(2)}',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: busy ? null : onDelete,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                color: Colors.redAccent,
                tooltip: 'Remove item',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
