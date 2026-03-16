import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NanaTheme {
  static ThemeData get lightTheme {
    const palette = NanaPalette(
      ricePaper: Color(0xFFFAF9F6),
      forestSage: Color(0xFF728C69),
      earthUmber: Color(0xFF4B3D33),
      warmSand: Color(0xFFD2B48C),
      skyMist: Color(0xFFA4B9C0),
      successEmerald: Color(0xFF2E8B57),
      sunGlow: Color(0xFFF0B33A),
      cardBlue: Color(0xFFDCE8ED),
      cardSoft: Color(0xFFF5E8DC),
      softGreen: Color(0xFFDCE5D8),
      softYellow: Color(0xFFFFF6D5),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.forestSage,
      brightness: Brightness.light,
      surface: palette.ricePaper,
    ).copyWith(
      primary: palette.forestSage,
      secondary: palette.skyMist,
      tertiary: palette.sunGlow,
      surface: palette.ricePaper,
      onSurface: palette.earthUmber,
      surfaceContainerHighest: const Color(0xFFF1ECE6),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: palette.ricePaper,
      colorScheme: colorScheme,
      textTheme: TextTheme(
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 36,
          height: 1.05,
          fontWeight: FontWeight.w700,
          color: palette.earthUmber,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: palette.earthUmber,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: palette.earthUmber,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: palette.earthUmber,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: palette.earthUmber,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          height: 1.45,
          color: palette.earthUmber,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          height: 1.45,
          color: palette.earthUmber.withOpacity(0.85),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          height: 1.4,
          color: palette.earthUmber.withOpacity(0.8),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: palette.forestSage,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.ricePaper,
        foregroundColor: palette.earthUmber,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: palette.earthUmber,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.ricePaper,
        indicatorColor: palette.skyMist.withOpacity(0.25),
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>(
          (Set<MaterialState> states) {
            final selected = states.contains(MaterialState.selected);
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? palette.forestSage : palette.earthUmber,
            );
          },
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.forestSage,
          foregroundColor: palette.ricePaper,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.forestSage,
          side: BorderSide(color: palette.forestSage.withOpacity(0.35)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: palette.forestSage, width: 1.3),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.cardSoft,
        selectedColor: palette.softGreen,
        labelStyle: GoogleFonts.inter(
          color: palette.earthUmber,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[palette],
    );
  }
}

class NanaColors {
  static NanaPalette of(BuildContext context) {
    return Theme.of(context).extension<NanaPalette>()!;
  }
}

@immutable
class NanaPalette extends ThemeExtension<NanaPalette> {
  const NanaPalette({
    required this.ricePaper,
    required this.forestSage,
    required this.earthUmber,
    required this.warmSand,
    required this.skyMist,
    required this.successEmerald,
    required this.sunGlow,
    required this.cardBlue,
    required this.cardSoft,
    required this.softGreen,
    required this.softYellow,
  });

  final Color ricePaper;
  final Color forestSage;
  final Color earthUmber;
  final Color warmSand;
  final Color skyMist;
  final Color successEmerald;
  final Color sunGlow;
  final Color cardBlue;
  final Color cardSoft;
  final Color softGreen;
  final Color softYellow;

  @override
  NanaPalette copyWith({
    Color? ricePaper,
    Color? forestSage,
    Color? earthUmber,
    Color? warmSand,
    Color? skyMist,
    Color? successEmerald,
    Color? sunGlow,
    Color? cardBlue,
    Color? cardSoft,
    Color? softGreen,
    Color? softYellow,
  }) {
    return NanaPalette(
      ricePaper: ricePaper ?? this.ricePaper,
      forestSage: forestSage ?? this.forestSage,
      earthUmber: earthUmber ?? this.earthUmber,
      warmSand: warmSand ?? this.warmSand,
      skyMist: skyMist ?? this.skyMist,
      successEmerald: successEmerald ?? this.successEmerald,
      sunGlow: sunGlow ?? this.sunGlow,
      cardBlue: cardBlue ?? this.cardBlue,
      cardSoft: cardSoft ?? this.cardSoft,
      softGreen: softGreen ?? this.softGreen,
      softYellow: softYellow ?? this.softYellow,
    );
  }

  @override
  NanaPalette lerp(ThemeExtension<NanaPalette>? other, double t) {
    if (other is! NanaPalette) {
      return this;
    }

    return NanaPalette(
      ricePaper: Color.lerp(ricePaper, other.ricePaper, t) ?? ricePaper,
      forestSage: Color.lerp(forestSage, other.forestSage, t) ?? forestSage,
      earthUmber: Color.lerp(earthUmber, other.earthUmber, t) ?? earthUmber,
      warmSand: Color.lerp(warmSand, other.warmSand, t) ?? warmSand,
      skyMist: Color.lerp(skyMist, other.skyMist, t) ?? skyMist,
      successEmerald:
          Color.lerp(successEmerald, other.successEmerald, t) ?? successEmerald,
      sunGlow: Color.lerp(sunGlow, other.sunGlow, t) ?? sunGlow,
      cardBlue: Color.lerp(cardBlue, other.cardBlue, t) ?? cardBlue,
      cardSoft: Color.lerp(cardSoft, other.cardSoft, t) ?? cardSoft,
      softGreen: Color.lerp(softGreen, other.softGreen, t) ?? softGreen,
      softYellow: Color.lerp(softYellow, other.softYellow, t) ?? softYellow,
    );
  }
}
