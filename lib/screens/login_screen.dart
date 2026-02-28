// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _loading = false;

  static const _lime = Color(0xFFC1FF72);

  Future<void> _sendOtp() async {
    setState(() => _loading = true);

    await Supabase.instance.client.auth.signInWithOtp(
      email: _emailController.text.trim(),
    );

    setState(() {
      _isOtpSent = true;
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OTP sent to your email")),
    );
  }

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);

    final response =
    await Supabase.instance.client.auth.verifyOTP(
      email: _emailController.text.trim(),
      token: _otpController.text.trim(),
      type: OtpType.email,
    );

    setState(() => _loading = false);

    if (response.session != null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                "Welcome Back 👋",
                style: AppTextStyles(context)
                    .display18W700
                    .copyWith(fontSize: 34, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                "Enter your email to continue",
                style: AppTextStyles(context)
                    .display14W400
                    .copyWith(color: const Color(0xFF666666)),
              ),
              const SizedBox(height: 40),

              // Email Field
              _inputField(
                  _emailController, "Email", Icons.email_outlined),

              const SizedBox(height: 20),

              if (_isOtpSent)
                _inputField(
                    _otpController, "Enter OTP", Icons.lock_outline),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : _isOtpSent
                      ? _verifyOtp
                      : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                      color: Colors.black)
                      : Text(
                    _isOtpSent ? "Verify OTP" : "Send OTP",
                    style: AppTextStyles(context)
                        .display16W700
                        .copyWith(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
      TextEditingController controller,
      String hint,
      IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF444444)),
        prefixIcon: Icon(icon, color: const Color(0xFF555555)),
        filled: true,
        fillColor: const Color(0xFF111111),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}