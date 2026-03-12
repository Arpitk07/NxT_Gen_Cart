import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A widget that wraps its child with a styled tooltip and a subtle
/// hover-scale effect – giving every interactive element a polished,
/// "finished" feel.
class HoverTooltip extends StatefulWidget {
  final Widget child;
  final String message;
  final double scaleOnHover;

  const HoverTooltip({
    super.key,
    required this.child,
    required this.message,
    this.scaleOnHover = 1.04,
  });

  @override
  State<HoverTooltip> createState() => _HoverTooltipState();
}

class _HoverTooltipState extends State<HoverTooltip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.message,
      preferBelow: false,
      verticalOffset: 14,
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF533483)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedScale(
          scale: _hovering ? widget.scaleOnHover : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
