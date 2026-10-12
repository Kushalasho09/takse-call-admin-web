import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/admin_colors.dart';
import '../theme/takse_call_logo_data.dart';

class AdminSplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const AdminSplashScreen({super.key, required this.onFinish});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  String _statusText = 'Initializing Secure Admin Telemetry Node...';
  double _progress = 0.15;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutBack,
    );

    _opacityAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeIn,
    );

    _animCtrl.forward();

    // Sequence of loading steps
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() { _statusText = 'Verifying Firestore Multi-Tenant Clusters...'; _progress = 0.50; });
    });
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() { _statusText = 'Establishing Live Real-Time Socket Connection...'; _progress = 0.85; });
    });
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) setState(() { _statusText = 'System Nominal • 99.98% SLA Ready'; _progress = 1.0; });
    });
    _stepTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) widget.onFinish();
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Stack(
        children: [
          // Background ambient radial lights
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AdminColors.primary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -120,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFDC2626).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _opacityAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo with glowing neon border
                    Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AdminColors.primary.withValues(alpha: 0.35),
                            blurRadius: 36,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                            blurRadius: 28,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: TakseCallLogo.widget(
                        borderRadius: BorderRadius.circular(20),
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Brand Typography
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TAKSE ',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        Text(
                          'CALL',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Text(
                        'SUPER ADMIN COMMAND PLATFORM',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AdminColors.accentCyan,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Progress Bar
                    SizedBox(
                      width: 240,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: AdminColors.surfaceSubtle,
                              color: AdminColors.primaryLight,
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _statusText,
                              key: ValueKey(_statusText),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AdminColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Skip button
                    TextButton(
                      onPressed: widget.onFinish,
                      child: Text(
                        'Skip to Console →',
                        style: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Version Stamp
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Takse Call Enterprise Operations • v2.17.2 Cloud Node',
                style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
