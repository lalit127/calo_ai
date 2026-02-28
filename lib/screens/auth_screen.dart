// lib/screens/auth/auth_screen.dart
import 'dart:async';
import 'package:cal_ai/services/dart/api_service.dart';
import 'package:cal_ai/services/dart/supabase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

enum AuthStep { enterEmail, enterOtp }

class AuthProvider extends ChangeNotifier {
  AuthStep step = AuthStep.enterEmail;
  bool loading = false;
  String? error;
  String email = '';
  int resendSeconds = 0;
  Timer? _resendTimer;

  // ── Send OTP ─────────────────────────────────────────────────────────────
  Future<void> sendOtp(String rawEmail) async {
    final e = rawEmail.trim().toLowerCase();
    if (!_isValidEmail(e)) {
      error = 'Please enter a valid email address';
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    final err = await authService.sendOtp(e);

    loading = false;

    if (err != null) {
      error = err;
      notifyListeners();
      return;
    }

    email = e;
    step = AuthStep.enterOtp;
    _startResendTimer();
    notifyListeners();
  }

  // ── Verify OTP ───────────────────────────────────────────────────────────
  Future<bool> verifyOtp(String otp) async {
    if (otp.length < 6) {
      error = 'Please enter the full 6-digit code';
      notifyListeners();
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    final err = await authService.verifyOtp(email, otp);

    loading = false;

    if (err != null) {
      error = err;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  // ── Resend ───────────────────────────────────────────────────────────────
  Future<void> resendOtp() async {
    if (resendSeconds > 0) return;

    loading = true;
    error = null;
    notifyListeners();

    await authService.sendOtp(email);

    loading = false;
    _startResendTimer();
    notifyListeners();
  }

  void goBackToEmail() {
    step = AuthStep.enterEmail;
    error = null;
    notifyListeners();
  }

  // ── Timer — uses a real Timer.periodic, not Future.doWhile ───────────────
  void _startResendTimer() {
    _resendTimer?.cancel();
    resendSeconds = 30;
    notifyListeners();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      resendSeconds--;
      notifyListeners();
      if (resendSeconds <= 0) t.cancel();
    });
  }

  bool _isValidEmail(String e) => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(e);

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SCREEN — injects the provider
// ═══════════════════════════════════════════════════════════════════════════

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const _AuthView(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  VIEW
// ═══════════════════════════════════════════════════════════════════════════

class _AuthView extends StatefulWidget {
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final List<TextEditingController> _otpCtrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  late AnimationController _slideCtrl;

  static const kLime = Color(0xFFC1FF72);
  static const kBlack = Color(0xFF000000);
  static const kSurface = Color(0xFF111111);
  static const kGray = Color(0xFF888888);
  static const kGray2 = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocus.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocus) f.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _otpValue => _otpCtrls.map((c) => c.text).join();

  void _clearOtp() {
    for (final c in _otpCtrls) c.clear();
    _otpFocus[0].requestFocus();
  }

  void _onOtpChanged(int index, String value) {
    setState(() {}); // refresh box borders
    if (value.length == 1) {
      if (index < 5) {
        _otpFocus[index + 1].requestFocus();
      } else {
        _otpFocus[index].unfocus();
        _submitOtp();
      }
    } else if (value.isEmpty && index > 0) {
      _otpFocus[index - 1].requestFocus();
    }
  }

  Future<void> _submitEmail() async {
    final auth = context.read<AuthProvider>();
    await auth.sendOtp(_emailCtrl.text);

    if (!mounted) return;
    if (auth.step == AuthStep.enterOtp) {
      _slideCtrl.forward(from: 0);
      Future.delayed(
        const Duration(milliseconds: 100),
        () => _otpFocus[0].requestFocus(),
      );
    }
  }

  Future<void> _submitOtp() async {
    final success = await context.read<AuthProvider>().verifyOtp(_otpValue);
    if (!mounted) return;
    if (!success) {
      _clearOtp();
      return;
    }
    _navigateAfterAuth();
  }

  Future<void> _navigateAfterAuth() async {
    try {
      final profile = await apiService.getProfile();
      final hasName =
          (profile['name'] as String?)?.isNotEmpty == true &&
          profile['name'] != profile['email']?.split('@')[0];
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacementNamed(hasName ? '/home' : '/onboarding');
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // context.watch rebuilds the whole view on every notifyListeners()
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBlack,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: size.height - MediaQuery.of(context).padding.top - 20,
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  _buildLogo(),
                  const SizedBox(height: 48),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.15, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: auth.step == AuthStep.enterEmail
                          ? _buildEmailStep(auth)
                          : _buildOtpStep(auth),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────
  Widget _buildLogo() => Column(
    children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: kLime,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(child: Text('🥗', style: TextStyle(fontSize: 40))),
      ),
      const SizedBox(height: 16),
      const Text(
        'Cal AI',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Track calories with a snap',
        style: TextStyle(color: kGray, fontSize: 15),
      ),
    ],
  );

  // ── Email step ────────────────────────────────────────────────────────────
  Widget _buildEmailStep(AuthProvider auth) => Column(
    key: const ValueKey('email'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Sign in or Sign up',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        "Enter your email — we'll send you a verification code",
        style: TextStyle(color: kGray, fontSize: 14, height: 1.5),
      ),
      const SizedBox(height: 32),
      _buildLabel('Email address'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _emailCtrl,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submitEmail(),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: _inputDecor('you@example.com'),
      ),
      if (auth.error != null) ...[
        const SizedBox(height: 12),
        _buildError(auth.error!),
      ],
      const Spacer(),
      _buildPrimaryButton(
        label: 'Send Verification Code',
        loading: auth.loading,
        onTap: _submitEmail,
      ),
      const SizedBox(height: 16),
      Center(
        child: Text(
          'By continuing you agree to our Terms & Privacy Policy',
          style: const TextStyle(color: kGray, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 24),
    ],
  );

  // ── OTP step ──────────────────────────────────────────────────────────────
  Widget _buildOtpStep(AuthProvider auth) => Column(
    key: const ValueKey('otp'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: () {
          _clearOtp();
          context.read<AuthProvider>().goBackToEmail();
        },
        child: const Row(
          children: [
            Icon(Icons.arrow_back_ios, color: kGray, size: 16),
            SizedBox(width: 4),
            Text('Change email', style: TextStyle(color: kGray, fontSize: 14)),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Check your email',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 8),
      RichText(
        text: TextSpan(
          style: const TextStyle(color: kGray, fontSize: 14, height: 1.5),
          children: [
            const TextSpan(text: 'We sent a 6-digit code to '),
            TextSpan(
              text: auth.email,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 36),
      _buildLabel('Verification code'),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, _buildOtpBox),
      ),
      if (auth.error != null) ...[
        const SizedBox(height: 12),
        _buildError(auth.error!),
      ],
      const SizedBox(height: 20),
      Center(
        child: GestureDetector(
          onTap: auth.resendSeconds == 0
              ? () async {
                  await context.read<AuthProvider>().resendOtp();
                  _clearOtp();
                }
              : null,
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14),
              children: [
                const TextSpan(
                  text: "Didn't receive code? ",
                  style: TextStyle(color: kGray),
                ),
                TextSpan(
                  text: auth.resendSeconds > 0
                      ? 'Resend in ${auth.resendSeconds}s'
                      : 'Resend',
                  style: TextStyle(
                    color: auth.resendSeconds > 0 ? kGray : kLime,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const Spacer(),
      _buildPrimaryButton(
        label: 'Verify & Continue',
        loading: auth.loading,
        onTap: _submitOtp,
      ),
      const SizedBox(height: 24),
    ],
  );

  // ── OTP box ───────────────────────────────────────────────────────────────
  Widget _buildOtpBox(int index) {
    final filled = _otpCtrls[index].text.isNotEmpty;
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _otpCtrls[index],
        focusNode: _otpFocus[index],
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kLime, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: filled ? kLime.withOpacity(0.5) : Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        onChanged: (v) => _onOtpChanged(index, v),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: kGray,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kGray2, fontSize: 15),
    filled: true,
    fillColor: kSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kLime, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  );

  Widget _buildError(String msg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFF4444).withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFFF4444), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(color: Color(0xFFFF4444), fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _buildPrimaryButton({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: kLime,
        foregroundColor: kBlack,
        disabledBackgroundColor: kLime.withOpacity(0.4),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: kBlack),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
    ),
  );
}
