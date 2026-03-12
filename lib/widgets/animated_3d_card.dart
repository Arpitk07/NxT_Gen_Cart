import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A widget that provides a 3D perspective tilt effect on hover/touch
class Animated3DCard extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final Duration duration;

  const Animated3DCard({
    super.key,
    required this.child,
    this.maxTilt = 0.05,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<Animated3DCard> createState() => _Animated3DCardState();
}

class _Animated3DCardState extends State<Animated3DCard> {
  double _rotateX = 0;
  double _rotateY = 0;

  void _onHover(PointerEvent event) {
    final size = context.size;
    if (size == null) return;
    final x = (event.localPosition.dx - size.width / 2) / size.width;
    final y = (event.localPosition.dy - size.height / 2) / size.height;
    setState(() {
      _rotateY = x * widget.maxTilt;
      _rotateX = -y * widget.maxTilt;
    });
  }

  void _onExit(PointerEvent event) {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rotateX)
          ..rotateY(_rotateY),
        transformAlignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

/// A widget that flips between front and back with a 3D rotation
class Animated3DFlip extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;
  final bool showFront;

  const Animated3DFlip({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 600),
    this.showFront = true,
  });

  @override
  State<Animated3DFlip> createState() => _Animated3DFlipState();
}

class _Animated3DFlipState extends State<Animated3DFlip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
    if (!widget.showFront) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(Animated3DFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFront != oldWidget.showFront) {
      widget.showFront ? _controller.reverse() : _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final angle = _animation.value * math.pi;
        final isFront = angle < math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isFront
              ? widget.front
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: widget.back,
                ),
        );
      },
    );
  }
}

/// Staggered slide-fade animation for list items
class SlideInAnimation extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + delay * index,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Floating animated background particle/orb effect
class FloatingOrb extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final Offset offset;

  const FloatingOrb({
    super.key,
    this.size = 100,
    this.color = Colors.white,
    this.duration = const Duration(seconds: 3),
    this.offset = Offset.zero,
  });

  @override
  State<FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<FloatingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(
            widget.offset.dx + math.sin(value * math.pi) * 15,
            widget.offset.dy + math.cos(value * math.pi) * 20,
          ),
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.color.withValues(alpha: 0.3),
              widget.color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
