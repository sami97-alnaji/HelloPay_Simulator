import 'package:flutter/material.dart';

/// Centralized light HelloPay-inspired design tokens.
abstract final class AppColors {
  static const hpOrange = Color(0xFFEE4A22);
  static const hpOrangeDark = Color(0xFFD93B1D);
  static const hpGreen = Color(0xFF8FBE32);
  static const hpLime = Color(0xFFB5CF3B);
  static const hpYellowGreen = Color(0xFFD9DC3A);
  static const hpBackground = Color(0xFFFFFFFF);
  static const hpSurfaceMuted = Color(0xFFF5F5F2);
  static const hpSurface = Color(0xFFFFFFFF);
  static const hpText = Color(0xFF292929);
  static const hpTextMuted = Color(0xFF6C6C6C);
  static const hpBorder = Color(0xFFD8D8D3);
  static const hpSuccess = Color(0xFF58A832);
  static const hpWarning = Color(0xFFEFAE22);
  static const hpDeclined = Color(0xFFD9382B);
}

abstract final class AppSpacing {
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0, xxl = 48.0;
}

abstract final class AppRadius {
  static const small = Radius.circular(8);
  static const medium = Radius.circular(12);
  static const large = Radius.circular(16);
}

abstract final class AppDurations {
  static const instant = Duration.zero;
  static const fast = Duration(milliseconds: 300);
  static const standard = Duration(milliseconds: 600);
  static const training = Duration(seconds: 2);
}

abstract final class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.hpBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.hpOrange,
          onPrimary: Colors.white,
          secondary: AppColors.hpGreen,
          onSecondary: Colors.white,
          surface: AppColors.hpSurface,
          onSurface: AppColors.hpText,
          error: AppColors.hpDeclined,
        ),
        dividerColor: AppColors.hpBorder,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.hpText),
          bodyMedium: TextStyle(color: AppColors.hpText),
          bodySmall: TextStyle(color: AppColors.hpTextMuted),
          headlineMedium:
              TextStyle(color: AppColors.hpText, fontWeight: FontWeight.w700),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.hpOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(AppRadius.medium)),
          ),
        ),
      );
}
