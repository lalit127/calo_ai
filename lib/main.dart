import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sizer/sizer.dart';

import 'providers/app_providers.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/dart/supabase_auth_service.dart';

const _supabaseUrl = 'https://dorhojloptefwmhjfchb.supabase.co';
const _supabaseAnonKey = 'YOUR_ANON_KEY';
const kOnboardingDoneKey = 'onboarding_complete';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initSystemUI();
  await _initSupabase();
  await authService.restoreSession();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const CalAIApp(),
    ),
  );
}

Future<void> _initSystemUI() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
}

Future<void> _initSupabase() async {
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
    authOptions:
    const FlutterAuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
}

class CalAIApp extends StatelessWidget {
  const CalAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (_, __, ___) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme,
        routes: {
          '/home': (_) => const HomeScreen(),
          '/auth': (_) => const AuthScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
        },
        home: const _AuthGate(),
      ),
    );
  }
}

/* ----------------------- AUTH GATE ----------------------- */

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (_, snapshot) {
        final session =
            snapshot.data?.session ?? client.auth.currentSession;

        if (session == null) return const AuthScreen();

        return FutureBuilder<bool>(
          future: _onboardingDone(),
          builder: (_, snap) {
            if (!snap.hasData) return const _Splash();
            return snap.data! ? const HomeScreen() : const OnboardingScreen();
          },
        );
      },
    );
  }

  Future<bool> _onboardingDone() async =>
      (await SharedPreferences.getInstance())
          .getBool(kOnboardingDoneKey) ??
          false;
}

/* ----------------------- THEME ----------------------- */

final _theme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: Colors.black,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFC1FF72),
    onPrimary: Colors.black,
    surface: Color(0xFF111111),
    onSurface: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFC1FF72),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      minimumSize: const Size(double.infinity, 56),
    ),
  ),
);

/* ----------------------- SPLASH ----------------------- */

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Color(0xFFC1FF72),
      ),
    ),
  );
}