import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/product_card.dart';
import '../widgets/stat_card.dart';
import 'checkout_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, cart),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStats(context, cart),
                      const SizedBox(height: 32),
                      _buildSectionTitle(context, "Products Overview"),
                      const SizedBox(height: 16),
                      _buildProductsList(cart),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header matching the reference: Title, Subtitle, SYNC DATA, Checkout button
  Widget _buildHeader(BuildContext context, CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "NxT-Gen Store",
                      style: AppTheme.heading(context).copyWith(
                        fontSize: 32,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Smart trolley connected",
                          style: AppTheme.subheading(context).copyWith(
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (cart.error == null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              "LIVE",
                              style: TextStyle(
                                color: AppTheme.successGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              "OFFLINE",
                              style: TextStyle(
                                color: AppTheme.errorRed,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      cart.retryConnection();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textMain,
                      side: const BorderSide(color: AppTheme.glassBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: AppTheme.glassBackground,
                    ),
                    child: Text(
                      "SYNC DATA",
                      style: AppTheme.title(context).copyWith(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: cart.items.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      shadowColor: AppTheme.accentPurpleLight,
                      elevation: 8,
                    ),
                    child: Text(
                      "Checkout",
                      style: AppTheme.title(context).copyWith(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Stats array overview
  Widget _buildStats(BuildContext context, CartProvider cart) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: "TOTAL ITEMS",
            value: "${cart.totalItems} units",
            icon: Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: "CART VALUE",
            value: "₹${cart.totalPrice.toStringAsFixed(2)}",
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTheme.title(context).copyWith(fontSize: 20),
    );
  }

  Widget _buildProductsList(CartProvider cart) {
    if (cart.isLoading && cart.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPurpleLight),
          ),
        ),
      );
    }

    if (cart.items.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      key: ValueKey(cart.items.length),
      children: cart.items.map((item) {
        return ProductCard(
          item: item,
          busy: false,
          isRecent: cart.isRecentlyAdded(item.id),
          loadingSuggestions: cart.isSuggestionsLoading(item.id),
          suggestions: cart.getSuggestionsFor(item.id),
          onTapCard: () {},
          onIncrement: () => cart.addOrIncrementItem(item, quantityIncrement: 1),
          onDecrement: () => cart.decrementItem(item.id),
          onDelete: () => cart.removeItem(item.id),
          onTapSuggestion: (suggestion) => cart.addCatalogProduct(suggestion.id, quantityIncrement: 1),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: AppTheme.accentPurpleLight,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Products Overview",
              style: TextStyle(
                color: AppTheme.textMain,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your virtual cart is currently empty. Start building your\npremium collection by scanning an item.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}