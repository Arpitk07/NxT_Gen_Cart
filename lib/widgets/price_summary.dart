import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'glass_container.dart';

class PriceSummary extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double total;

  const PriceSummary({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _row(context, 'Subtotal', subtotal, false),
          const SizedBox(height: 12),
          _row(context, 'Tax', tax, false),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppTheme.glassBorder, height: 1),
          ),
          _row(context, 'Total', total, true),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, double value, bool highlight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.subheading(context).copyWith(
            color: highlight ? AppTheme.textMain : AppTheme.textSecondary,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            fontSize: highlight ? 18 : 15,
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: AppTheme.price(context).copyWith(
            color: highlight ? AppTheme.accentPurpleLight : AppTheme.textMain,
            fontWeight: FontWeight.w700,
            fontSize: highlight ? 20 : 16,
          ),
        ),
      ],
    );
  }
}
