import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_state_service.dart';
import '../theme/admin_colors.dart';
import '../theme/takse_call_logo_data.dart';

class AdminLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const AdminLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController(text: 'master.admin@taksecall.com');
  final _passCtrl = TextEditingController(text: 'TakseAdmin@2026');
  bool _obscurePassword = true;
  bool _rememberTerminal = true;
  bool _isLoading = false;
  String? _errorMsg;

  void _fillDefaultCredentials() {
    setState(() {
      _emailCtrl.text = 'master.admin@taksecall.com';
      _passCtrl.text = 'TakseAdmin@2026';
      _errorMsg = null;
    });
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    final success = await AdminStateService.instance.login(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.onLoginSuccess();
      } else {
        setState(() => _errorMsg = 'Invalid Super Admin credentials. Verify email/password or click "Quick Fill Master Credentials" below.');
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Stack(
        children: [
          // Background ambient gradient glow
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AdminColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AdminColors.accentCyan.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            right: 28,
            child: InkWell(
              onTap: () => AdminStateService.instance.toggleTheme(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AdminStateService.instance.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      size: 16,
                      color: AdminStateService.instance.isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AdminStateService.instance.isDarkMode ? 'Dark Mode (App)' : 'Light Mode (Web)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                width: 460,
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AdminColors.border, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: AdminColors.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo Emblem
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AdminColors.borderBright, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AdminColors.primary.withValues(alpha: 0.35),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TakseCallLogo.widget(
                          borderRadius: BorderRadius.circular(16),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TAKSE ',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AdminColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'CALL',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFDC2626),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AdminColors.primaryGlow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AdminColors.primary.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              'SUPER ADMIN CONSOLE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: AdminColors.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Master control platform for organizations, devices & global call analytics.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AdminColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AdminColors.errorSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.error.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AdminColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AdminColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Email Field
                    Text(
                      'Admin Master Email',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'admin@taksecall.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded, color: AdminColors.textSecondary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Security Master Key',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Super Admin credentials managed via master root vault.'),
                                backgroundColor: AdminColors.surfaceElevated,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Text(
                            'Reset Token?',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AdminColors.primaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter security passkey',
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: AdminColors.textSecondary, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AdminColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Quick Fill Chip
                    InkWell(
                      onTap: _fillDefaultCredentials,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AdminColors.primaryGlow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.key_rounded, size: 14, color: AdminColors.primaryLight),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Quick Fill: master.admin@taksecall.com / TakseAdmin@2026',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AdminColors.primaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Remember Terminal Checkbox
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberTerminal,
                            activeColor: AdminColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            side: BorderSide(color: AdminColors.borderBright),
                            onChanged: (v) => setState(() => _rememberTerminal = v ?? true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Keep super-admin terminal authorized',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AdminColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // Primary Sign In Button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Access Super Admin Console',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Security Badges Footer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSubtle.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AdminColors.success, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '256-Bit TLS • Internal Operations Node v2.17',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AdminColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
