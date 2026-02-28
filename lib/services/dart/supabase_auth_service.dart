// lib/services/supabase_auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseAuthService {
  final _client = Supabase.instance.client;

  // ── Current user ─────────────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;
  bool  get isLoggedIn  => currentUser != null;

  /// Access token — sent to Python backend as Bearer token
  String? get accessToken => _client.auth.currentSession?.accessToken;

  // ── Email OTP flow ────────────────────────────────────────────────────────

  /// Step 1: Send OTP to email
  /// Returns null on success, error message on failure
  Future<String?> sendOtp(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,    // auto-creates account if new user
        emailRedirectTo: null,     // use OTP not magic link
      );
      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Failed to send OTP. Check your internet connection.';
    }
  }

  /// Step 2: Verify OTP entered by user
  /// Returns null on success, error message on failure
  Future<String?> verifyOtp(String email, String otp) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.user != null) {
        // Ensure user profile exists in our users table
        await _ensureProfile(response.user!);
        await _saveSession();
        return null; // success
      }
      return 'Verification failed. Please try again.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Invalid OTP. Please check and try again.';
    }
  }

  /// Called on app start — restores session from storage
  Future<bool> restoreSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session != null && !_isExpired(session)) {
        return true;
      }
      // Try refresh
      final refreshed = await _client.auth.refreshSession();
      return refreshed.session != null;
    } catch (_) {
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('calai_session');
  }

  // ── Listen to auth state changes ──────────────────────────────────────────

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Private helpers ───────────────────────────────────────────────────────

  bool _isExpired(Session session) {
    if (session.expiresAt == null) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(
        session.expiresAt! * 1000);
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)));
  }

  Future<void> _saveSession() async {
    // supabase_flutter handles session persistence automatically
    // This is just for any custom logic you want to add
  }

  Future<void> _ensureProfile(User user) async {
    // Upsert into our public.users table
    // The trigger handles this automatically on signup,
    // but we also do it here as a safety net
    try {
      await _client.from('users').upsert({
        'id':    user.id,
        'email': user.email,
        'name':  user.userMetadata?['name'] ?? user.email!.split('@')[0],
      }, onConflict: 'id');
    } catch (e) {
      // Profile already exists — fine
    }
  }
}

final authService = SupabaseAuthService();