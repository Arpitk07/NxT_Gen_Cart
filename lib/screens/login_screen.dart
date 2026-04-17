import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/hover_tooltip.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _formController;
  late AnimationController _bgController;
  late Animation<double> _formSlide;
  late Animation<double> _formFade;

  @override
  void initState() {
    super.initState();
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _formSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _formController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _formController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DashboardScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated dark gradient background with teal accents
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final v = _bgController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                        -1.0 + v * 0.3, -1.0 + math.sin(v * math.pi) * 0.2),
                    end: Alignment(
                        1.0 - v * 0.2, 1.0 - math.cos(v * math.pi) * 0.3),
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
              final size = MediaQuery.of(context).size;
              return Stack(
                children: [
                  Positioned(
                    top: size.height * 0.1 + math.sin(v * math.pi) * 20,
                    right: 30,
                    child: _glowOrb(100, AppTheme.accentPurple),
                  ),
                  Positioned(
                    bottom: size.height * 0.1 + math.cos(v * math.pi) * 25,
                    left: 20,
                    child: _glowOrb(70, const Color(0xFF0D9488)),
                  ),
                  Positioned(
                    bottom: size.height * 0.4,
                    right: size.width * 0.1,
                    child: _glowOrb(50, const Color(0xFF1A3A5C)),
                  ),
                ],
              );
            },
          ),

          // Subtle tagline (top left aligned with reference)
          Positioned(
            top: 60,
            left: 40,
            child: FadeTransition(
              opacity: _formFade,
              child: SizedBox(
                width: 200,
                child: Text(
                  'SECURE ACCESS TO YOUR\nPERSONAL DIGITAL WARDROBE\nAND CURATED MARKETPLACE\nEXPERIENCE.',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),

          // Login form
          SafeArea(
            child: Center(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: AnimatedBuilder(
                  animation: _formController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _formSlide.value),
                      child: Opacity(
                        opacity: _formFade.value,
                        child: child,
                      ),
                    );
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cart logo with lightning badge
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A2E),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentPurple.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.shopping_cart_rounded,
                                    size: 36,
                                    color: AppTheme.accentPurpleLight,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D4AA),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00D4AA).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'NxT-Gen ',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                              TextSpan(
                                text: 'Cart',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.accentPurpleLight,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'THE FUTURE OF COMMERCE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Glass card form
                        GlassContainer(
                          padding: const EdgeInsets.all(28),
                          opacity: 0.06,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back',
                                style: AppTheme.heading(context).copyWith(fontSize: 24),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Please enter your credentials to continue',
                                style: AppTheme.body(context).copyWith(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Email
                              Text(
                                'EMAIL ADDRESS',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _emailController,
                                hint: 'name@example.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 20),

                              // Password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PASSWORD',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'FORGOT PASSWORD?',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppTheme.accentPurpleLight,
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _passwordController,
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Sign In button - glowing purple
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accentPurple.withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentPurple,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'SIGN IN',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // OR
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppTheme.glassBorder)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppTheme.glassBorder)),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Continue as Guest
                        HoverTooltip(
                          message: 'Browse without signing in',
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => const DashboardScreen()),
                              );
                            },
                            icon: const Icon(Icons.person_outline_rounded, size: 20),
                            label: Text(
                              'CONTINUE AS GUEST',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: const BorderSide(color: AppTheme.glassBorder),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Create Account',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentPurpleLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentPurple, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
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
