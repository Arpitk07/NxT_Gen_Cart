import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../utils/expiry_utils.dart';
import '../widgets/price_summary.dart';
import '../widgets/product_card.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _pendingItemIds = <String>{};
  final TextEditingController _searchController = TextEditingController();

  bool _isClearing = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
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
          backgroundColor: const Color(0xFF141A30),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clear cart failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  Future<void> _openManualAddSheet(CartProvider provider) async {
    if (provider.catalogProducts.isEmpty) {
      await provider.loadCatalogProducts();
    }
    if (!mounted) return;

    String query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12182C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final results = provider.catalogProducts.where((product) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              return product.name.toLowerCase().contains(q) ||
                  product.id.toLowerCase().contains(q);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Manual Add (Testing)',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (value) => setSheetState(() => query = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search products',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white54,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final product = results[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ListTile(
                              title: Text(
                                product.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Rs ${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white54),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle_rounded,
                                  color: Color(0xFF7C3AED),
                                ),
                                onPressed: () async {
                                  await _runItemAction(
                                    product.id,
                                    () => provider.addCatalogProduct(product.id),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product.name} added to cart'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProductDetails(CartItem item) {
    final status = ExpiryUtils.getExpiryStatus(item.expiry);
    final statusColor = ExpiryUtils.getStatusColor(status);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12182C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  item.name,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rs ${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _detailRow('Product ID', item.id),
                _detailRow('Quantity', '${item.quantity}'),
                _detailRow('Expiry', item.expiry),
                _detailRow('Status', ExpiryUtils.getStatusText(status)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ExpiryUtils.getStatusText(status),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Smart Cart',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => IconButton(
              tooltip: 'Manual add product',
              onPressed: () => _openManualAddSheet(cart),
              icon: const Icon(Icons.add_box_rounded, color: Color(0xFF7C3AED)),
            ),
          ),
          Consumer<CartProvider>(
            builder: (_, cart, __) {
              final disabled = _isClearing || cart.isLoading || cart.items.isEmpty;
              return IconButton(
                tooltip: 'Clear cart',
                onPressed: disabled ? null : () => _confirmClearCart(cart),
                icon: _isClearing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF090B14), Color(0xFF12182C), Color(0xFF161230)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              if (cartProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (cartProvider.error != null && cartProvider.items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.redAccent),
                        const SizedBox(height: 14),
                        Text(
                          'Connection issue',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cartProvider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white60),
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
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 42,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan a product to begin',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final filteredItems = cartProvider.items.where((item) {
                if (_searchQuery.trim().isEmpty) return true;
                final q = _searchQuery.toLowerCase().trim();
                return item.name.toLowerCase().contains(q) ||
                    item.id.toLowerCase().contains(q);
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search products',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                      ),
                    ),
                  ),
                  if (cartProvider.hasExpiredItems)
                    Container(
                      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Checkout disabled: remove expired items first.',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No products match your search',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final busy = _pendingItemIds.contains(item.id);
                              final loadingSuggestions =
                                  cartProvider.isSuggestionsLoading(item.id);
                              final suggestions = cartProvider.getSuggestionsFor(item.id);

                              if (!cartProvider.hasSuggestionsLoaded(item.id) &&
                                  !loadingSuggestions) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  context.read<CartProvider>().loadSuggestionsFor(item);
                                });
                              }

                              final isRecent = cartProvider.isRecentlyAdded(item.id);

                              return TweenAnimationBuilder<double>(
                                key: ValueKey('${item.id}-${item.quantity}-${item.timestamp}'),
                                tween: Tween<double>(begin: isRecent ? 0 : 1, end: 1),
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, (1 - value) * 20),
                                      child: child,
                                    ),
                                  );
                                },
                                child: ProductCard(
                                  item: item,
                                  busy: busy,
                                  isRecent: isRecent,
                                  loadingSuggestions: loadingSuggestions,
                                  suggestions: suggestions,
                                  onTapCard: () => _showProductDetails(item),
                                  onIncrement: () => _runItemAction(
                                    item.id,
                                    () => cartProvider.addOrIncrementItem(item),
                                  ),
                                  onDecrement: () => _runItemAction(
                                    item.id,
                                    () => cartProvider.decrementItem(item.id),
                                  ),
                                  onDelete: () => _runItemAction(
                                    item.id,
                                    () => cartProvider.removeItem(item.id),
                                  ),
                                  onTapSuggestion: (suggestedItem) => _runItemAction(
                                    suggestedItem.id,
                                    () => cartProvider.addOrIncrementItem(suggestedItem),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12182C),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.32),
                          blurRadius: 14,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PriceSummary(
                            subtotal: cartProvider.subtotal,
                            tax: cartProvider.tax,
                            total: cartProvider.total,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: cartProvider.hasExpiredItems
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const CheckoutScreen(),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.shopping_bag_rounded),
                              label: const Text('Checkout'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
