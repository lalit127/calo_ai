// lib/main.dart
import 'package:cal_ai/providers/app_providers.dart';
import 'package:cal_ai/screens/auth_screen.dart';
import 'package:cal_ai/services/dart/supabase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sizer/sizer.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

const _supabaseUrl     = 'https://dorhojloptefwmhjfchb.supabase.co';
const _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvcmhvamxvcHRlZndtaGpmY2hiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyNDg1MzgsImV4cCI6MjA4NzgyNDUzOH0.X2yeKiHaz9WXpjhu5B9lFAFgG5b9A2yWDipXzsMOKj4';
const kOnboardingDoneKey = 'onboarding_complete'; // public so onboarding_screen can use it

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                    Colors.transparent,
    statusBarIconBrightness:           Brightness.light,
    systemNavigationBarColor:          Color(0xFF000000),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await Supabase.initialize(
    url:     _supabaseUrl,
    anonKey: _supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  await authService.restoreSession();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const CalAIApp(),
    ),
  );
}

class CalAIApp extends StatelessWidget {
  const CalAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title:                      'Cal AI',
          debugShowCheckedModeBanner: false,
          theme:                      _buildTheme(),
          routes: {
            '/home':       (_) => const HomeScreen(),
            '/auth':       (_) => const AuthScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
          },
          home: const _AuthGate(),
        );
      },
    );
  }

  ThemeData _buildTheme() => ThemeData(
    brightness:              Brightness.dark,
    useMaterial3:            true,
    scaffoldBackgroundColor: const Color(0xFF000000),
    colorScheme: const ColorScheme.dark(
      primary:    Color(0xFFC1FF72),
      onPrimary:  Color(0xFF000000),
      surface:    Color(0xFF111111),
      background: Color(0xFF000000),
      onSurface:  Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor:        Colors.black,
      foregroundColor:        Colors.white,
      elevation:              0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 18,
        fontWeight: FontWeight.w700, letterSpacing: -0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC1FF72),
        foregroundColor: Colors.black,
        elevation:       0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        minimumSize: const Size(double.infinity, 56),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:    true,
      fillColor: const Color(0xFF111111),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:   BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC1FF72), width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 15),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

// ── Auth Gate — single source of truth for routing ────────────────────────────
// Logic:
//   No session          → AuthScreen (OTP login)
//   Session + no flag   → OnboardingScreen (new user)
//   Session + flag set  → HomeScreen (returning user)
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Still connecting to auth stream
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Check if we already have a session (from restoreSession)
          final existingSession = Supabase.instance.client.auth.currentSession;
          if (existingSession == null) return const _SplashScreen();
        }

        // Get session from stream OR fallback to current session
        final session = snapshot.data?.session
            ?? Supabase.instance.client.auth.currentSession;

        // No session → must log in
        if (session == null) return const AuthScreen();

        // Has session → check onboarding flag
        return FutureBuilder<bool>(
          future: _isOnboardingDone(),
          builder: (context, snap) {
            if (!snap.hasData) return const _SplashScreen();
            // ✅ Flag set → Home, else → Onboarding
            return snap.data! ? const HomeScreen() : const OnboardingScreen();
          },
        );
      },
    );
  }

  // ✅ SIMPLE: just check SharedPreferences flag
  // Set by onboarding_screen.dart when user completes onboarding
  Future<bool> _isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kOnboardingDoneKey) ?? false;
  }
}

// ── Splash ────────────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF000000),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🥗', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text('Cal AI',
                style: TextStyle(
                  color: Colors.white, fontSize: 28,
                  fontWeight: FontWeight.w800, letterSpacing: -0.5,
                )),
            SizedBox(height: 32),
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFC1FF72)),
            ),
          ],
        ),
      ),
    );
  }
}