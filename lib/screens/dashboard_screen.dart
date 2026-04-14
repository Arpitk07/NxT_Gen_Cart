import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(cart),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStoreCard(),

                      const SizedBox(height: 20),

                      _buildStats(cart),

                      const SizedBox(height: 20),

                      _buildSectionTitle("Live Cart"),

                      const SizedBox(height: 10),

                      _buildProducts(cart),

                      const SizedBox(height: 20),

                      _buildActions(context, cart),
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

  // 🔥 HEADER WITH CONNECTION STATUS
  Widget _buildHeader(CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            "NxT-Gen Cart",
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          // 🔥 CONNECTION STATUS
          Row(
            children: [
              Icon(
                cart.error == null ? Icons.circle : Icons.error,
                color: cart.error == null ? Colors.green : Colors.red,
                size: 10,
              ),
              const SizedBox(width: 6),
              Text(
                cart.error == null ? "Connected" : "Error",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔥 STORE CARD
  Widget _buildStoreCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF533483)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          Icon(Icons.store, color: Colors.white),
          SizedBox(width: 10),
          Text("NxT-Gen Store", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // 🔥 STATS
  Widget _buildStats(CartProvider cart) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            "Items",
            "${cart.totalItems}",
            Icons.inventory,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            "Value",
            "₹${cart.totalPrice.toStringAsFixed(0)}",
            Icons.currency_rupee,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white)),
          Text(title, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  // 🔥 TITLE
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // 🔥 PRODUCT LIST (REAL-TIME)
  Widget _buildProducts(CartProvider cart) {
    if (cart.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cart.items.isEmpty) {
      return Center(
        child: Column(
          children: const [
            Icon(Icons.shopping_cart_outlined,
                size: 40, color: Colors.white38),
            SizedBox(height: 10),
            Text(
              "Scan a product to begin",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return Column(
      children: cart.items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading:
                const Icon(Icons.inventory_2, color: Colors.white),
            title: Text(item.name,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              "Qty: ${item.quantity}",
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: Text(
              "₹${item.price}",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 🔥 ACTION BUTTONS
  Widget _buildActions(BuildContext context, CartProvider cart) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text("View Cart"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed:
                cart.items.isEmpty ? null : () => cart.clearCart(),
            icon: const Icon(Icons.delete),
            label: const Text("Clear Cart"),
          ),
        ),
      ],
    );
  }
}