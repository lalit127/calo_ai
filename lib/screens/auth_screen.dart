// lib/screens/auth/auth_screen.dart
import 'dart:async';
import 'package:cal_ai/main.dart'; // for kOnboardingDoneKey
import 'package:cal_ai/screens/home_screen.dart';
import 'package:cal_ai/screens/onboarding_screen.dart';
import 'package:cal_ai/services/dart/supabase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


// ═══════════════════════════════════════════════════════════════════════════
//  PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

enum OtpStep { enterEmail, enterCode }

class AuthProvider extends ChangeNotifier {
  OtpStep step          = OtpStep.enterEmail;
  bool    loading       = false;
  String? error;
  String  email         = '';
  int     resendSeconds = 0;
  Timer?  _resendTimer;

  Future<void> sendOtp(String rawEmail) async {
    final e = rawEmail.trim().toLowerCase();
    if (!_isValidEmail(e)) {
      error = 'Please enter a valid email address';
      notifyListeners();
      return;
    }
    loading = true; error = null;
    notifyListeners();
    final err = await authService.sendOtp(e);
    loading = false;
    if (err != null) { error = err; notifyListeners(); return; }
    email = e;
    step  = OtpStep.enterCode;
    _startResendTimer();
    notifyListeners();
  }

  Future<bool> verifyOtp(String code) async {
    if (code.length != 6) {
      error = 'Please enter the full 6-digit code';
      notifyListeners();
      return false;
    }
    loading = true; error = null;
    notifyListeners();
    final err = await authService.verifyOtp(email, code);
    loading = false;
    if (err != null) { error = err; notifyListeners(); return false; }
    notifyListeners();
    return true;
  }

  Future<void> resend() async {
    if (resendSeconds > 0) return;
    loading = true; error = null;
    notifyListeners();
    await authService.sendOtp(email);
    loading = false;
    _startResendTimer();
    notifyListeners();
  }

  void changeEmail() { step = OtpStep.enterEmail; error = null; notifyListeners(); }

  void _startResendTimer() {
    _resendTimer?.cancel();
    resendSeconds = 60;
    notifyListeners();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      resendSeconds--;
      notifyListeners();
      if (resendSeconds <= 0) t.cancel();
    });
  }

  bool _isValidEmail(String e) => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(e);

  @override
  void dispose() { _resendTimer?.cancel(); super.dispose(); }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SCREEN
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

class _AuthView extends StatefulWidget {
  const _AuthView();
  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  final _emailCtrl  = TextEditingController();
  final _emailFocus = FocusNode();
  final _otpCtrls   = List.generate(6, (_) => TextEditingController());
  final _otpFocus   = List.generate(6, (_) => FocusNode());
  bool  _navigating = false;

  static const kLime    = Color(0xFFC1FF72);
  static const kBlack   = Color(0xFF000000);
  static const kSurface = Color(0xFF111111);
  static const kGray    = Color(0xFF888888);
  static const kGray2   = Color(0xFF333333);

  @override
  void dispose() {
    _emailCtrl.dispose(); _emailFocus.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocus) f.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    await context.read<AuthProvider>().sendOtp(_emailCtrl.text);
    if (mounted && context.read<AuthProvider>().step == OtpStep.enterCode) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _otpFocus[0].requestFocus();
      });
    }
  }

  Future<void> _submitOtp() async {
    final code = _otpCtrls.map((c) => c.text).join();
    final ok   = await context.read<AuthProvider>().verifyOtp(code);
    if (ok && mounted) await _navigateAfterAuth();
  }

  // ✅ KEY FIX: Navigate based on SharedPreferences flag ONLY
  Future<void> _navigateAfterAuth() async {
    if (_navigating || !mounted) return;
    _navigating = true;
    try {
      final prefs       = await SharedPreferences.getInstance();
      final isOnboarded = prefs.getBool(kOnboardingDoneKey) ?? false;

      if (!mounted) return;

      if (isOnboarded) {
        // Returning user — go straight to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
        );
      } else {
        // New user — go to onboarding
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => OnboardingScreen()),
              (route) => false,
        );
      }
    } finally {
      _navigating = false;
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _otpFocus[index + 1].requestFocus();
      } else {
        _otpFocus[index].unfocus();
        _submitOtp();
      }
    }
  }

  void _onOtpKeyDown(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpCtrls[index].text.isEmpty &&
        index > 0) {
      _otpFocus[index - 1].requestFocus();
      _otpCtrls[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          begin: const Offset(0.15, 0), end: Offset.zero,
                        ).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: auth.step == OtpStep.enterEmail
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

  Widget _buildLogo() => Column(
    children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: kLime, borderRadius: BorderRadius.circular(22)),
        child: const Center(child: Text('🥗', style: TextStyle(fontSize: 40))),
      ),
      const SizedBox(height: 16),
      const Text('Cal AI', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
      const SizedBox(height: 6),
      const Text('Track calories with a snap', style: TextStyle(color: kGray, fontSize: 15)),
    ],
  );

  Widget _buildEmailStep(AuthProvider auth) => Column(
    key: const ValueKey('email'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Sign in or Sign up', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      const Text("Enter your email — we'll send you a 6-digit code.", style: TextStyle(color: kGray, fontSize: 14, height: 1.5)),
      const SizedBox(height: 32),
      const Text('EMAIL ADDRESS', style: TextStyle(color: kGray, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
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
      if (auth.error != null) ...[const SizedBox(height: 12), _errorBox(auth.error!)],
      const Spacer(),
      _primaryButton(label: 'Send Code', icon: Icons.send_rounded, loading: auth.loading, onTap: _submitEmail),
      const SizedBox(height: 16),
      const Center(child: Text('By continuing you agree to our Terms & Privacy Policy', style: TextStyle(color: kGray, fontSize: 11), textAlign: TextAlign.center)),
      const SizedBox(height: 24),
    ],
  );

  Widget _buildOtpStep(AuthProvider auth) => Column(
    key: const ValueKey('otp'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: () => context.read<AuthProvider>().changeEmail(),
        child: const Row(children: [
          Icon(Icons.arrow_back_ios, color: kGray, size: 16),
          SizedBox(width: 4),
          Text('Change email', style: TextStyle(color: kGray, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 32),
      Center(
        child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF1E1E1E))),
          child: const Center(child: Text('📩', style: TextStyle(fontSize: 40))),
        ),
      ),
      const SizedBox(height: 24),
      const Text('Check your email', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 8),
      RichText(
        text: TextSpan(
          style: const TextStyle(color: kGray, fontSize: 14, height: 1.6),
          children: [
            const TextSpan(text: 'We sent a 6-digit code to\n'),
            TextSpan(text: auth.email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      const SizedBox(height: 28),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (i) => _otpBox(i)),
      ),
      if (auth.error != null) ...[const SizedBox(height: 16), _errorBox(auth.error!)],
      const SizedBox(height: 24),
      _primaryButton(label: 'Verify Code', icon: Icons.check_circle_outline_rounded, loading: auth.loading, onTap: _submitOtp),
      const Spacer(),
      Center(
        child: GestureDetector(
          onTap: auth.resendSeconds == 0 ? () => context.read<AuthProvider>().resend() : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: auth.resendSeconds > 0 ? kSurface : kLime.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: auth.resendSeconds > 0 ? const Color(0xFF1E1E1E) : kLime.withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh_rounded, size: 16, color: auth.resendSeconds > 0 ? kGray : kLime),
              const SizedBox(width: 8),
              Text(
                auth.resendSeconds > 0 ? 'Resend in ${auth.resendSeconds}s' : 'Resend code',
                style: TextStyle(color: auth.resendSeconds > 0 ? kGray : kLime, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 24),
    ],
  );

  Widget _otpBox(int index) => SizedBox(
    width: 46, height: 56,
    child: RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (e) => _onOtpKeyDown(index, e),
      child: TextFormField(
        controller: _otpCtrls[index],
        focusNode: _otpFocus[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: kSurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF222222), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLime, width: 2)),
        ),
        onChanged: (v) => _onOtpChanged(index, v),
      ),
    ),
  );

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kGray2, fontSize: 15),
    filled: true, fillColor: kSurface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kLime, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  );

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFF4444).withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Color(0xFFFF4444), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFFFF4444), fontSize: 13))),
    ]),
  );

  Widget _primaryButton({required String label, required IconData icon, required bool loading, required VoidCallback onTap}) =>
      SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: kLime, foregroundColor: kBlack,
            disabledBackgroundColor: kLime.withOpacity(0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: kBlack))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: kBlack),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          ]),
        ),
      );
}