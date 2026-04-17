import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cart_item_model.dart';
import '../utils/expiry_utils.dart';
import 'hover_tooltip.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final int index;

  const CartItemTile({super.key, required this.item, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final expiryStatus = ExpiryUtils.getExpiryStatus(item.expiry);
    final statusColor = ExpiryUtils.getStatusColor(expiryStatus);
    final statusText = ExpiryUtils.getStatusText(expiryStatus);

    return HoverTooltip(
      message:
          '${item.name.isNotEmpty ? item.name : "Unknown"} - Tap for details',
      scaleOnHover: 1.03,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.06),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showItemDetails(
              context,
              expiryStatus,
              statusColor,
              statusText,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getProductIcon(expiryStatus),
                      color: statusColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name.isNotEmpty
                                    ? item.name
                                    : 'Unknown Product',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(statusText, statusColor),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.qr_code_rounded,
                              size: 14,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.id.isNotEmpty ? item.id : 'N/A',
                              style: GoogleFonts.poppins(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.event_outlined,
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.expiry.isNotEmpty ? item.expiry : 'N/A',
                              style: GoogleFonts.poppins(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Present',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6C63FF),
                        ),
                      ),
                      Text(
                        'Total',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  IconData _getProductIcon(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return Icons.warning_amber_rounded;
      case ExpiryStatus.nearExpiry:
        return Icons.access_time_rounded;
      case ExpiryStatus.safe:
        return Icons.check_circle_outline_rounded;
    }
  }

  void _showItemDetails(
    BuildContext context,
    ExpiryStatus status,
    Color statusColor,
    String statusText,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              item.name.isNotEmpty ? item.name : 'Unknown',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.qr_code_rounded, 'Product ID', item.id),
            _detailRow(
              Icons.currency_rupee_rounded,
              'Unit Price',
              '₹${item.price.toStringAsFixed(2)}',
            ),
            _detailRow(
              Icons.shopping_bag_rounded,
              'Status',
              'Present in cart',
            ),
            _detailRow(
              Icons.currency_rupee_rounded,
              'Price',
              '₹${item.price.toStringAsFixed(2)}',
            ),
            _detailRow(Icons.event_outlined, 'Expiry Date', item.expiry),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_getProductIcon(status), color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white38),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value.isNotEmpty ? value : 'N/A',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
