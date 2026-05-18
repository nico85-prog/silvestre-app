import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SilvestrePalette extends ThemeExtension<SilvestrePalette> {
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;

  const SilvestrePalette({
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    this.success = const Color(0xFF3DA35D),
    this.warning = const Color(0xFFE0A91B),
    this.error = const Color(0xFFD64545),
  });

  @override
  SilvestrePalette copyWith({
    Color? primary,
    Color? primaryDark,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return SilvestrePalette(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  SilvestrePalette lerp(ThemeExtension<SilvestrePalette>? other, double t) {
    if (other is! SilvestrePalette) return this;
    return SilvestrePalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

class SilvestreThemeSpec {
  final String id;
  final String name;
  final String tagline;
  final IconData icon;
  final SilvestrePalette palette;
  final TextTheme Function(TextTheme base) textTheme;

  const SilvestreThemeSpec({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.palette,
    required this.textTheme,
  });

  ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      primary: palette.primary,
      onPrimary: Colors.white,
      secondary: palette.secondary,
      onSecondary: Colors.white,
      surface: palette.background,
      onSurface: palette.textPrimary,
      error: palette.error,
      brightness: Brightness.light,
    );

    final baseText = ThemeData.light().textTheme;
    final tt = textTheme(baseText).apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: tt,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: tt.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
    );
  }
}

class SilvestreThemes {
  static final classic = SilvestreThemeSpec(
    id: 'classic',
    name: 'Classic',
    tagline: 'Logo originale',
    icon: Icons.camera_alt_outlined,
    palette: const SilvestrePalette(
      primary: Color(0xFFF47521),
      primaryDark: Color(0xFFD85F12),
      secondary: Color(0xFF7A7A7A),
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFF7F7F7),
      textPrimary: Color(0xFF2B2B2B),
      textSecondary: Color(0xFF7A7A7A),
      border: Color(0xFFE0E0E0),
    ),
    textTheme: (base) => GoogleFonts.interTextTheme(base),
  );

  static final heritage = SilvestreThemeSpec(
    id: 'heritage',
    name: 'Heritage',
    tagline: 'Studio storico, dal 1970',
    icon: Icons.theaters_outlined,
    palette: const SilvestrePalette(
      primary: Color(0xFFC75D2C),
      primaryDark: Color(0xFF9F4720),
      secondary: Color(0xFF8A6A4A),
      background: Color(0xFFFBF6EE),
      surface: Color(0xFFF3ECDF),
      textPrimary: Color(0xFF2A2622),
      textSecondary: Color(0xFF6B5E51),
      border: Color(0xFFE2D7C2),
    ),
    textTheme: (base) => GoogleFonts.playfairDisplayTextTheme(base),
  );

  static final modernStudio = SilvestreThemeSpec(
    id: 'modern_studio',
    name: 'Modern Studio',
    tagline: 'Pulito, geometrico',
    icon: Icons.auto_awesome_outlined,
    palette: const SilvestrePalette(
      primary: Color(0xFFE25822),
      primaryDark: Color(0xFFB4421A),
      secondary: Color(0xFF1F3A47),
      background: Color(0xFFFAF9F7),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1F3A47),
      textSecondary: Color(0xFF5B6E78),
      border: Color(0xFFE3E6E8),
    ),
    textTheme: (base) => GoogleFonts.spaceGroteskTextTheme(base),
  );

  static final sunsetSoft = SilvestreThemeSpec(
    id: 'sunset_soft',
    name: 'Sunset Soft',
    tagline: 'Caldo, familiare',
    icon: Icons.wb_twilight,
    palette: const SilvestrePalette(
      primary: Color(0xFFFF6B45),
      primaryDark: Color(0xFFE04E2A),
      secondary: Color(0xFFFFB088),
      background: Color(0xFFFFF7F1),
      surface: Color(0xFFFFEEDE),
      textPrimary: Color(0xFF3D2817),
      textSecondary: Color(0xFF8B6F5A),
      border: Color(0xFFF2DDC9),
    ),
    textTheme: (base) => GoogleFonts.dmSerifDisplayTextTheme(base),
  );

  static final mono = SilvestreThemeSpec(
    id: 'mono',
    name: 'Mono Bold',
    tagline: 'Solo nero + arancio',
    icon: Icons.dark_mode_outlined,
    palette: const SilvestrePalette(
      primary: Color(0xFFFF7A2C),
      primaryDark: Color(0xFFE05C0A),
      secondary: Color(0xFF1A1A1A),
      background: Color(0xFFF5F5F5),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1A1A1A),
      textSecondary: Color(0xFF6E6E6E),
      border: Color(0xFFD8D8D8),
    ),
    textTheme: (base) => GoogleFonts.workSansTextTheme(base),
  );

  static final all = <SilvestreThemeSpec>[
    classic,
    heritage,
    modernStudio,
    sunsetSoft,
    mono,
  ];

  static SilvestreThemeSpec byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => classic);
}
