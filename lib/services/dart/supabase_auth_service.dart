// lib/services/supabase_auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseAuthService {
  final _client = Supabase.instance.client;

  /* ───────────────── CURRENT USER ───────────────── */

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentUser != null;
  String? get userId => currentUser?.id;
  String? get userEmail => currentUser?.email;
  String? get accessToken => currentSession?.accessToken;

  /* ───────────────── SEND OTP ───────────────── */

  Future<String?> sendOtp(String email) async {
    try {
      await _client.auth
          .signInWithOtp(email: email, shouldCreateUser: true)
          .timeout(const Duration(seconds: 15));

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Network error. Please try again.';
    }
  }

  /* ───────────────── VERIFY OTP ───────────────── */

  Future<String?> verifyOtp(String email, String otp) async {
    try {
      final res = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (res.session == null || res.user == null) {
        return 'Verification failed. Try again.';
      }

      await _ensureProfile(res.user!);
      return null;

    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      if (msg.contains('expired')) {
        return 'Code expired. Request a new one.';
      }
      if (msg.contains('invalid')) {
        return 'Invalid code. Please try again.';
      }
      return e.message;
    } catch (_) {
      return 'Verification failed. Check your connection.';
    }
  }

  /* ───────────────── RESTORE SESSION ───────────────── */

  Future<bool> restoreSession() async {
    try {
      final session = _client.auth.currentSession;

      if (session != null) return true;

      final refreshed = await _client.auth.refreshSession();
      return refreshed.session != null;

    } catch (_) {
      return false;
    }
  }

  /* ───────────────── SIGN OUT ───────────────── */

  Future<void> signOut() async {
    await _client.auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // cleaner than removing individually
  }

  /* ───────────────── AUTH STREAM ───────────────── */

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  /* ───────────────── PROFILE UPSERT ───────────────── */

  Future<void> _ensureProfile(User user) async {
    try {
      await _client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'name': user.userMetadata?['name'] ??
            user.email?.split('@').first,
      }, onConflict: 'id');
    } catch (_) {}
  }
}

final authService = SupabaseAuthService();