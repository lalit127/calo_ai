// lib/main.dart
// Flow: First launch → Onboarding → Auth → Home
//       Returning user → Auth gate → Home
import 'package:cal_ai/providers/app_providers.dart';
import 'package:cal_ai/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sizer/sizer.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

const _supabaseUrl     = '';
const _supabaseAnonKey = '';

const _kOnboardingDone = 'onboarding_complete';

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
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Read onboarding flag before runApp so there's no flicker
  final prefs           = await SharedPreferences.getInstance();
  final onboardingDone  = prefs.getBool(_kOnboardingDone) ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: CalAIApp(onboardingDone: onboardingDone),
    ),
  );
}

class CalAIApp extends StatelessWidget {
  const CalAIApp({super.key, required this.onboardingDone});
  final bool onboardingDone;

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title:                    'Cal AI',
          debugShowCheckedModeBanner: false,
          theme:                    _buildTheme(),
          // Named routes used for post-auth navigation
          routes: {
            '/home':        (_) => const HomeScreen(),
            '/auth':        (_) => const AuthScreen(),
            '/onboarding':  (_) => const OnboardingScreen(),
          },
          home: onboardingDone
              ? const _AuthGate()       // returning user → check session
              : const OnboardingScreen(), // first launch → onboarding
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100)),
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

// ── Auth Gate — only reached after onboarding is done ────────────────────────
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final session = snapshot.data?.session;

        if (session == null) {
          return const AuthScreen();
        }

        return FutureBuilder<bool>(
          future: _isProfileComplete(),
          builder: (context, snap) {
            if (!snap.hasData) return const _SplashScreen();
            return snap.data! ? const HomeScreen() : const AuthScreen();
          },
        );
      },
    );
  }

  Future<bool> _isProfileComplete() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return false;
      final data = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', uid)
          .maybeSingle();
      if (data == null) return false;
      final name         = data['name'] as String?;
      final email        = Supabase.instance.client.auth.currentUser?.email ?? '';
      final defaultName  = email.split('@')[0];
      return name != null && name.isNotEmpty && name != defaultName;
    } catch (_) {
      return false;
    }
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