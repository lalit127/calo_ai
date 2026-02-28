import 'package:cal_ai/utils/base_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  CAL AI — COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primaryColor    = Color(0xFFC1FF72); // Cal AI lime green
  static const Color primary         = Color(0xFFC1FF72);
  static const Color primaryDark     = Color(0xFF9FD94E); // pressed state
  static const Color primaryLight    = Color(0xFFD4FF99); // soft lime

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color black           = Color(0xFF000000); // scaffold
  static const Color blackLight      = Color(0xFF0A0A0A); // bottom nav bar
  static const Color backgroundDark  = Color(0xFF000000);
  static const Color backgroundLight = Color(0xFF111111); // cards / surfaces
  static const Color surface2        = Color(0xFF1A1A1A); // elevated cards
  static const Color surface3        = Color(0xFF222222); // progress tracks

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color white           = Color(0xFFFFFFFF);
  static const Color whiteOff        = Color(0xFFEEEEEE); // body text
  static const Color grayLighter     = Color(0xFFCCCCCC); // secondary text
  static const Color grayLight       = Color(0xFF888888); // placeholder / hint
  static const Color grayDefault     = Color(0xFF555555); // muted
  static const Color grayDark        = Color(0xFF333333); // disabled
  static const Color grayDivider     = Color(0xFF1E1E1E); // dividers

  // ── Macros / Data colours ─────────────────────────────────────────────────
  static const Color protein         = Color(0xFF4ECDC4); // teal
  static const Color carbs           = Color(0xFFFFB347); // orange
  static const Color fat             = Color(0xFFFF6B9D); // pink
  static const Color fiber           = Color(0xFF90EE90); // soft green
  static const Color water           = Color(0xFF5BC0EB); // sky blue
  static const Color calories        = Color(0xFFC1FF72); // same as primary

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success         = Color(0xFFC1FF72);
  static const Color error           = Color(0xFFFF4444);
  static const Color warning         = Color(0xFFFFB347);
  static const Color info            = Color(0xFF5BC0EB);
}

// ═══════════════════════════════════════════════════════════════════════════
//  SIZES
// ═══════════════════════════════════════════════════════════════════════════

class AppSizes {
  AppSizes._();

  // Font
  static const double font_10 = 10;
  static const double font_12 = 12;
  static const double font_14 = 14;
  static const double font_16 = 16;
  static const double font_18 = 18;
  static const double font_20 = 20;
  static const double font_22 = 22;
  static const double font_24 = 24;
  static const double font_28 = 28;
  static const double font_32 = 32;
  static const double font_36 = 36;
  static const double font_42 = 42;

  // Radius
  static const double radius_4  = 4;
  static const double radius_8  = 8;
  static const double radius_12 = 12;
  static const double radius_14 = 14;
  static const double radius_16 = 16;
  static const double radius_18 = 18;
  static const double radius_20 = 20;
  static const double radius_24 = 24;
  static const double radius_100 = 100; // pill / fully rounded

  // Spacing
  static const double space_4  = 4;
  static const double space_8  = 8;
  static const double space_12 = 12;
  static const double space_16 = 16;
  static const double space_20 = 20;
  static const double space_24 = 24;
  static const double space_32 = 32;
}

// ═══════════════════════════════════════════════════════════════════════════
//  APP THEMES
// ═══════════════════════════════════════════════════════════════════════════

class AppThemes {

  // ── Light Theme ───────────────────────────────────────────────────────────
  // Cal AI is dark-first; light theme uses soft whites with lime accents
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,

    // ── System UI
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primaryColor,
      selectionColor: AppColors.primaryColor.withOpacity(0.3),
      selectionHandleColor: AppColors.primaryColor,
    ),

    // ── Scaffold & Backgrounds
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    dialogBackgroundColor: Colors.white,
    canvasColor: Colors.white,

    // ── Brand
    primaryColor: AppColors.primary,
    primaryColorDark: AppColors.primaryDark,
    primaryColorLight: AppColors.primaryLight,

    fontFamily: BaseFonts.sf_pro,

    // ── ColorScheme
    colorScheme: const ColorScheme.light(
      primary:    AppColors.primary,
      onPrimary:  AppColors.black,        // text ON lime button = black
      secondary:  AppColors.primaryLight,
      onSecondary: AppColors.black,
      surface:    Colors.white,
      onSurface:  Color(0xFF111111),
      background: Color(0xFFF5F5F5),
      onBackground: Color(0xFF111111),
      error:      AppColors.error,
      onError:    Colors.white,
    ),

    // ── AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF111111),
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: const IconThemeData(color: Color(0xFF111111)),
      titleTextStyle: const TextStyle(
        color: Color(0xFF111111),
        fontSize: AppSizes.font_20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        fontFamily: BaseFonts.sf_pro,
      ),
    ),

    // ── Cards
    cardColor: Colors.white,
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_20),
        side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_14),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_14),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFAAAAAA),
        fontSize: AppSizes.font_14,
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 18, vertical: 16),
    ),

    // ── Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.black,   // black text on lime
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius_100)),
        minimumSize: const Size(double.infinity, 56),
        textStyle: const TextStyle(
          fontSize: AppSizes.font_16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          fontFamily: BaseFonts.sf_pro,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF111111),
        side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius_100)),
        minimumSize: const Size(double.infinity, 56),
        textStyle: const TextStyle(
          fontSize: AppSizes.font_16,
          fontWeight: FontWeight.w600,
          fontFamily: BaseFonts.sf_pro,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius_8)),
        textStyle: const TextStyle(
          fontSize: AppSizes.font_14,
          fontWeight: FontWeight.w600,
          fontFamily: BaseFonts.sf_pro,
        ),
      ),
    ),

    // ── Text Theme
    textTheme: _buildTextTheme(isLight: true),

    // ── Icon
    iconTheme: const IconThemeData(color: Color(0xFF555555)),

    // ── Bottom Nav
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withOpacity(0.15),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: BaseFonts.sf_pro,
          );
        }
        return const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 11,
          fontWeight: FontWeight.w400,
          fontFamily: BaseFonts.sf_pro,
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: Color(0xFFAAAAAA));
      }),
    ),

    // ── Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF111111),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: AppSizes.font_14,
        fontFamily: BaseFonts.sf_pro,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius_14)),
    ),

    // ── Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radius_24)),
      ),
    ),

    // ── Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.black,
      unselectedLabelColor: const Color(0xFF888888),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: AppSizes.font_14,
        fontFamily: BaseFonts.sf_pro,
      ),
      indicator: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.radius_100),
      ),
    ),

    // ── FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.black,
      elevation: 0,
    ),

    // ── Divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE),
      thickness: 1,
      space: 1,
    ),

    // ── Progress
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: Color(0xFFEEEEEE),
      circularTrackColor: Color(0xFFEEEEEE),
    ),

    // ── Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return AppColors.primary;
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(AppColors.black),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius_4)),
      side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
    ),

    bottomAppBarTheme: const BottomAppBarThemeData(color: Colors.white),
  );


  // ── Dark Theme ────────────────────────────────────────────────────────────
  // Primary Cal AI look — pure black + lime green
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    // ── System UI
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primaryColor,
      selectionColor: AppColors.primaryColor.withOpacity(0.3),
      selectionHandleColor: AppColors.primaryColor,
    ),

    // ── Scaffold & Backgrounds
    scaffoldBackgroundColor: AppColors.black,
    dialogBackgroundColor: AppColors.backgroundLight,
    canvasColor: AppColors.backgroundLight,

    // ── Brand
    primaryColor: AppColors.primary,
    primaryColorDark: AppColors.primaryDark,
    primaryColorLight: AppColors.primaryLight,

    fontFamily: BaseFonts.sf_pro,

    // ── ColorScheme
    colorScheme: const ColorScheme.dark(
      primary:      AppColors.primary,
      onPrimary:    AppColors.black,        // black text ON lime = readable
      secondary:    AppColors.primaryLight,
      onSecondary:  AppColors.black,
      surface:      AppColors.backgroundLight,  // #111111
      onSurface:    Colors.white,
      background:   AppColors.black,
      onBackground: Colors.white,
      error:        AppColors.error,
      onError:      Colors.white,
      outline:      AppColors.grayDivider,
    ),

    // ── AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: AppSizes.font_20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        fontFamily: BaseFonts.sf_pro,
      ),
    ),

    // ── Cards
    cardColor: AppColors.backgroundLight,
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.backgroundLight,   // #111111
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_20),
      ),
    ),

    // ── Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundLight, // #111111
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_14),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_14),
        borderSide: const BorderSide(color: AppColors.grayDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_14),
        borderSide: const BorderSide(
            color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius_14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: AppColors.grayDefault,  // #555555
        fontSize: AppSizes.font_14,
        fontFamily: BaseFonts.sf_pro,
      ),
      labelStyle: const TextStyle(
        color: AppColors.grayLight,   // #888888
        fontSize: AppSizes.font_14,
        fontFamily: BaseFonts.sf_pro,
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 18, vertical: 16),
    ),

    // ── Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,   // lime
        foregroundColor: AppColors.black,      // black text on lime
        disabledBackgroundColor: AppColors.grayDark,
        disabledForegroundColor: AppColors.grayLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius_100)),
        minimumSize: const Size(double.infinity, 56),
        textStyle: const TextStyle(
          fontSize: AppSizes.font_16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          fontFamily: BaseFonts.sf_pro,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF333333), width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius_100)),
        minimumSize: const Size(double.infinity, 56),
        textStyle: const TextStyle(
          fontSize: AppSizes.font_16,
          fontWeight: FontWeight.w600,
          fontFamily: BaseFonts.sf_pro,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,   // lime text buttons
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius_8)),
        textStyle: const TextStyle(
          fontSize: AppSizes.font_14,
          fontWeight: FontWeight.w600,
          fontFamily: BaseFonts.sf_pro,
        ),
      ),
    ),

    // ── Text Theme
    textTheme: _buildTextTheme(isLight: false),

    // ── Icon
    iconTheme: const IconThemeData(color: AppColors.grayLight),

    // ── Bottom Nav
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.blackLight,  // #0A0A0A
      indicatorColor: AppColors.primary.withOpacity(0.15),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: BaseFonts.sf_pro,
          );
        }
        return const TextStyle(
          color: AppColors.grayDefault,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          fontFamily: BaseFonts.sf_pro,
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return const IconThemeData(color: AppColors.grayDefault, size: 24);
      }),
    ),

    // ── Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.backgroundLight,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: AppSizes.font_14,
        fontFamily: BaseFonts.sf_pro,
      ),
      actionTextColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius_14)),
    ),

    // ── Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.backgroundLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radius_24)),
      ),
    ),

    // ── Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.black,
      unselectedLabelColor: AppColors.grayLight,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: AppSizes.font_14,
        fontFamily: BaseFonts.sf_pro,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: AppSizes.font_14,
        fontFamily: BaseFonts.sf_pro,
      ),
      indicator: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.radius_100),
      ),
      dividerColor: Colors.transparent,
    ),

    // ── FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.black,
      elevation: 0,
      shape: CircleBorder(),
    ),

    // ── Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.grayDivider,  // #1E1E1E
      thickness: 1,
      space: 1,
    ),

    // ── Progress Indicators
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surface3,  // #222222
      circularTrackColor: AppColors.surface3,
      linearMinHeight: 6,
    ),

    // ── Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      thumbColor: AppColors.primary,
      inactiveTrackColor: AppColors.surface3,
      overlayColor: AppColors.primary.withOpacity(0.2),
    ),

    // ── Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return AppColors.primary;
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(AppColors.black),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius_4)),
      side: const BorderSide(color: AppColors.grayDefault, width: 1.5),
    ),

    // ── Switch
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return AppColors.black;
        return AppColors.grayDefault;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return AppColors.primary;
        return AppColors.surface3;
      }),
    ),

    // ── List Tile
    listTileTheme: const ListTileThemeData(
      tileColor: AppColors.backgroundLight,
      textColor: Colors.white,
      iconColor: AppColors.grayLight,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    bottomAppBarTheme: const BottomAppBarThemeData(
      color: AppColors.blackLight,
      elevation: 0,
    ),
  );


  // ─────────────────────────────────────────────────────────────────────────
  // Shared TextTheme builder
  // ─────────────────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color primary   = isLight ? const Color(0xFF111111) : Colors.white;
    final Color secondary = isLight ? const Color(0xFF555555) : AppColors.grayLight;
    final Color muted     = isLight ? const Color(0xFF888888) : AppColors.grayDefault;

    return TextTheme(
      // 10px — labels, captions
      bodySmall: TextStyle(
        fontSize: AppSizes.font_10,
        fontWeight: FontWeight.w400,
        color: muted,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: 0.2,
      ),
      // 12px — supporting text
      bodyMedium: TextStyle(
        fontSize: AppSizes.font_12,
        fontWeight: FontWeight.w400,
        color: secondary,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: 0.2,
      ),
      // 14px — body copy
      bodyLarge: TextStyle(
        fontSize: AppSizes.font_14,
        fontWeight: FontWeight.w400,
        color: isLight ? const Color(0xFF333333) : AppColors.whiteOff,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: 0.1,
      ),
      // 16px — list items, input text
      labelLarge: TextStyle(
        fontSize: AppSizes.font_16,
        fontWeight: FontWeight.w500,
        color: primary,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: 0,
      ),
      // 11px — bottom nav labels, tags
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: muted,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: 0.5,
      ),
      // 18px — card titles
      titleMedium: TextStyle(
        fontSize: AppSizes.font_18,
        fontWeight: FontWeight.w600,
        color: primary,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: -0.3,
      ),
      // 20px — section headers
      titleLarge: TextStyle(
        fontSize: AppSizes.font_20,
        fontWeight: FontWeight.w700,
        color: primary,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: -0.5,
      ),
      // 22px — screen titles / appbar
      headlineSmall: TextStyle(
        fontSize: AppSizes.font_22,
        fontWeight: FontWeight.w800,
        color: primary,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: -0.5,
      ),
      // 28px — onboarding headings
      headlineMedium: TextStyle(
        fontSize: AppSizes.font_28,
        fontWeight: FontWeight.w800,
        color: primary,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      // 36px — hero numbers (calories remaining)
      headlineLarge: TextStyle(
        fontSize: AppSizes.font_36,
        fontWeight: FontWeight.w800,
        color: primary,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: -1.5,
        height: 1.0,
      ),
      // 24px — calorie count on cards
      displaySmall: TextStyle(
        fontSize: AppSizes.font_24,
        fontWeight: FontWeight.w700,
        color: primary,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: -0.8,
      ),
      // 32px — large stats
      displayMedium: TextStyle(
        fontSize: AppSizes.font_32,
        fontWeight: FontWeight.w800,
        color: primary,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: -1.2,
        height: 1.0,
      ),
      // 42px — ring center number
      displayLarge: TextStyle(
        fontSize: AppSizes.font_42,
        fontWeight: FontWeight.w800,
        color: primary,
        fontFamily: BaseFonts.sf_pro,
        letterSpacing: -2.0,
        height: 1.0,
      ),
    );
  }
}