import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _bgController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _badgeFade;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _logoRotate = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );
    _badgeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _logoController.forward().then((_) {
      _textController.forward();
    });

    _initializeApp();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Startup error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Deep dark background with subtle teal gradient
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final v = _bgController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + v * 0.3, -1.0),
                    end: Alignment(1.0, 1.0 - v * 0.2),
                    colors: const [
                      Color(0xFF0A0A10),
                      Color(0xFF0E0E18),
                      Color(0xFF0A1520),
                      Color(0xFF0B1A1A),
                    ],
                  ),
                ),
              );
            },
          ),

          // Subtle ambient glow orbs
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final v = _bgController.value;
              return Stack(
                children: [
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15 +
                        math.sin(v * math.pi) * 20,
                    right: MediaQuery.of(context).size.width * 0.1,
                    child: _buildOrb(140, const Color(0xFF7C3AED)),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.1 +
                        math.cos(v * math.pi) * 15,
                    left: MediaQuery.of(context).size.width * 0.05,
                    child: _buildOrb(100, const Color(0xFF0D9488)),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.25,
                    right: MediaQuery.of(context).size.width * 0.15,
                    child: _buildOrb(60, const Color(0xFF1A3A5C)),
                  ),
                ],
              );
            },
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cart icon with lightning badge
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_logoRotate.value)
                        ..scale(_logoScale.value),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Dark glass cart icon container
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentPurple.withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shopping_cart_rounded,
                              size: 48,
                              color: AppTheme.accentPurpleLight,
                            ),
                          ),
                        ),

                        // Lightning bolt badge (cyan)
                        Positioned(
                          top: -4,
                          right: 4,
                          child: FadeTransition(
                            opacity: _badgeFade,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D4AA),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D4AA).withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Animated title: NXT-GEN CART
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'NXT-GEN ',
                                style: GoogleFonts.inter(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              TextSpan(
                                text: 'CART',
                                style: GoogleFonts.inter(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.accentPurpleLight,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'SMART  •  FAST  •  FUTURISTIC',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.accentPurpleLight,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
