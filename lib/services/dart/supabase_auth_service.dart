// lib/services/supabase_auth_service.dart
// UPDATED: Magic link → OTP 6-digit code flow
// Removed: emailRedirectTo, handleMagicLink, app_links, kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseAuthService {
  final _client = Supabase.instance.client;

  // ── Current user ──────────────────────────────────────────────────────────
  User?    get currentUser    => _client.auth.currentUser;
  bool     get isLoggedIn     => currentUser != null;
  String?  get accessToken    => _client.auth.currentSession?.accessToken;
  Session? get currentSession => _client.auth.currentSession;
  String?  get userId         => currentUser?.id;
  String?  get userEmail      => currentUser?.email;

  // ── Step 1: Send OTP code to email ────────────────────────────────────────
  /// Sends a 6-digit code to [email] — NOT a magic link.
  /// Key: no emailRedirectTo = Supabase sends code instead of clickable link.
  Future<String?> sendOtp(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
        // ✅ No emailRedirectTo here — this is the fix
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timed out — check internet'),
      );
      return null; // null = success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Step 2: Verify 6-digit OTP code ──────────────────────────────────────
  /// Returns null on success, error string on failure.
  Future<String?> verifyOtp(String email, String otp) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      final session = response.session;
      final user    = response.user;

      if (session != null && user != null) {
        await _ensureProfile(user);
        await _persistUserData(user, session);
        return null; // ✅ success
      }

      return 'Verification failed. Please try again.';
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('expired')) {
        return 'Code expired. Please request a new one.';
      }
      if (e.message.toLowerCase().contains('invalid')) {
        return 'Invalid code. Please check and try again.';
      }
      return e.message;
    } catch (e) {
      return 'Verification error: $e';
    }
  }

  // ── Session restore on app launch ─────────────────────────────────────────
  Future<bool> restoreSession() async {
    try {
      final session = _client.auth.currentSession;
      final user    = _client.auth.currentUser;

      if (session != null && user != null && !_isExpired(session)) {
        await _persistUserData(user, session);
        return true;
      }

      // Try refreshing if expired
      final refreshed = await _client.auth.refreshSession();
      final rSession  = refreshed.session;
      final rUser     = rSession?.user;

      if (rSession != null && rUser != null) {
        await _persistUserData(rUser, rSession);
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserEmail);
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kExpiresAt);
  }

  // ── Auth state stream ─────────────────────────────────────────────────────
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Cached token helpers ──────────────────────────────────────────────────
  Future<String?> getCachedAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccessToken);
  }

  Future<Map<String, String?>> getCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId'      : prefs.getString(_kUserId),
      'email'       : prefs.getString(_kUserEmail),
      'accessToken' : prefs.getString(_kAccessToken),
      'refreshToken': prefs.getString(_kRefreshToken),
    };
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  static const _kUserId       = 'calai_user_id';
  static const _kUserEmail    = 'calai_user_email';
  static const _kAccessToken  = 'calai_access_token';
  static const _kRefreshToken = 'calai_refresh_token';
  static const _kExpiresAt    = 'calai_expires_at';

  Future<void> _persistUserData(User user, Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId,       user.id);
    await prefs.setString(_kUserEmail,    user.email ?? '');
    await prefs.setString(_kAccessToken,  session.accessToken);
    await prefs.setString(_kRefreshToken, session.refreshToken ?? '');
    if (session.expiresAt != null) {
      await prefs.setInt(_kExpiresAt, session.expiresAt!);
    }
  }

  bool _isExpired(Session session) {
    if (session.expiresAt == null) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)));
  }

  Future<void> _ensureProfile(User user) async {
    try {
      await _client.from('users').upsert({
        'id'   : user.id,
        'email': user.email,
        'name' : user.userMetadata?['name'] ?? user.email!.split('@')[0],
      }, onConflict: 'id');
    } catch (_) {}
  }
}

final authService = SupabaseAuthService();