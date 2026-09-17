import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna inti — emerald gelap + hitam hangat + emas pudar sebagai
/// aksen eksklusif. Sengaja BUKAN hitam pekat (#000) atau hijau neon,
/// supaya kesannya butik/mewah, bukan tema "gamer/tech".
class AppColors {
  AppColors._();

  // Latar & permukaan
  static const ink = Color(0xFF0B0F0D); // background utama
  static const surface = Color(0xFF141917); // kartu, app bar
  static const surfaceVariant = Color(0xFF1E2422); // field, divider, elemen sekunder

  // Emerald (warna utama brand)
  static const emerald = Color(0xFF1F6F52); // primary
  static const emeraldBright = Color(0xFF34A66F); // aksen interaktif/hover
  static const emeraldDeep = Color(0xFF123D2C); // varian gelap (container)

  // Emas pudar — dipakai SANGAT SEDIKIT, cuma untuk hal yang benar-benar
  // ingin ditonjolkan sebagai "eksklusif" (badge diskon tahunan, dst).
  static const gold = Color(0xFFC9A227);

  // Teks
  static const ivory = Color(0xFFEDEFEC); // teks utama di atas gelap
  static const muted = Color(0xFF9AA39D); // teks sekunder

  // Status semantik (menggantikan Colors.green/orange/red Material biasa
  // supaya senada dengan palet, bukan warna primer cerah standar)
  static const statusActive = emeraldBright;
  static const statusWarning = Color(0xFFD6A24B); // amber hangat, senada emas
  static const statusDanger = Color(0xFFC1484B); // merah anggur, tidak terlalu cerah
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      // Playfair Display untuk judul — kontras serif yang memberi kesan
      // butik/premium, dipakai HANYA untuk headline/title, bukan body text.
      headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.ivory),
      headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.ivory),
      headlineSmall: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ivory),
      titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ivory),
      titleMedium: GoogleFonts.manrope(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ivory),
      bodyLarge: GoogleFonts.manrope(fontSize: 15, color: AppColors.ivory),
      bodyMedium: GoogleFonts.manrope(fontSize: 14, color: AppColors.ivory),
      bodySmall: GoogleFonts.manrope(fontSize: 12, color: AppColors.muted),
      labelLarge: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.ivory),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.emeraldBright,
      onPrimary: AppColors.ink,
      primaryContainer: AppColors.emeraldDeep,
      onPrimaryContainer: AppColors.ivory,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ivory,
      error: AppColors.statusDanger,
      outline: AppColors.surfaceVariant,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ink,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.ivory,
        ),
        iconTheme: const IconThemeData(color: AppColors.ivory),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: AppColors.emeraldBright,
        textColor: AppColors.ivory,
        tileColor: Colors.transparent,
      ),

      dividerTheme: const DividerThemeData(color: AppColors.surfaceVariant, thickness: 1),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.emeraldBright, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emeraldBright,
          foregroundColor: AppColors.ink,
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ivory,
          side: const BorderSide(color: AppColors.surfaceVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.emeraldBright),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emeraldBright,
        foregroundColor: AppColors.ink,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: const TextStyle(color: AppColors.ivory, fontSize: 12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(color: AppColors.ivory),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surface),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ivory),
        contentTextStyle: GoogleFonts.manrope(color: AppColors.ivory),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariant,
        contentTextStyle: const TextStyle(color: AppColors.ivory),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.emeraldBright),
    );
  }
}
