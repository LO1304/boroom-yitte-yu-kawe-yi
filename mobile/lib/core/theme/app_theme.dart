import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// User-selectable structural & aesthetic UI Models (4 radically distinct looks).
enum UiVisualModel {
  glassLuxe(
    'glass_luxe',
    'Aurora Glass',
    'Verre dépoli lumineux, halos atmosphériques, dock flottant et icônes 3D',
    26.0,
    true,
  ),
  dynamicCommunity(
    'dynamic_community',
    'Néon Dynamique 3D',
    'Cartes tactiles relief 3D, dégradés vibrants et badges colorés par pilier',
    22.0,
    true,
  ),
  editorialMinimal(
    'editorial_minimal',
    'Studio Apple Minimal',
    'Contraste pur, lignes ultra-fines, typographie forte et calme visuel',
    18.0,
    false,
  ),
  sanctuaryClassic(
    'sanctuary_classic',
    'Palais Géométrique',
    'Parchemin chaleureux, géométrie Khatam dorée et élégance calligraphique',
    22.0,
    false,
  );

  const UiVisualModel(
    this.code,
    this.labelFr,
    this.descriptionFr,
    this.cardRadius,
    this.floatingNavBar,
  );

  final String code;
  final String labelFr;
  final String descriptionFr;
  final double cardRadius;
  final bool floatingNavBar;

  static UiVisualModel fromCode(String? code) {
    return UiVisualModel.values.firstWhere(
      (m) => m.code == code,
      orElse: () => UiVisualModel.glassLuxe,
    );
  }
}

/// 8 radical, unmistakable visual worlds (Light & Deep Dark aware).
enum SanctuaryPalette {
  emeraldGold(
    'emerald_gold',
    'Émeraude Impériale',
    'Aura émeraude vive, or liquide et verre cristallin',
    Color(0xFF008564),
    Color(0xFF033B2D),
    Color(0xFF10B981),
    Color(0xFFD1FAE5),
    Color(0xFF063729),
    Color(0xFFEEF7F4),
    Color(0xFFFFFFFF),
    Color(0xFFE0F1EB),
    Color(0xFF050E0C),
    Color(0xFF0C1A16),
    Color(0xFF122620),
    Color(0xFFE0A42A),
    Color(0xFFF6CA5B),
    Color(0xFFFEF3D6),
    Color(0xFF2B210E),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
  ),
  obsidianLuxe(
    'obsidian_luxe',
    'Obsidienne 24K',
    'Noir carbone haute couture, platine pur et or 24 carats',
    Color(0xFF141824),
    Color(0xFF05070C),
    Color(0xFF3B4861),
    Color(0xFFE5EAF2),
    Color(0xFF1A202E),
    Color(0xFFF2F4F8),
    Color(0xFFFFFFFF),
    Color(0xFFE6EAF0),
    Color(0xFF04060A),
    Color(0xFF0C1018),
    Color(0xFF141B27),
    Color(0xFFDFA934),
    Color(0xFFF7D06B),
    Color(0xFFFCF2D6),
    Color(0xFF2B210E),
    Color(0xFF64748B),
    Color(0xFFF5C451),
  ),
  medinaSapphire(
    'medina_sapphire',
    'Saphir Céleste',
    'Bleu cobalt électrique, lueur cyan et or stellaire',
    Color(0xFF1D4ED8),
    Color(0xFF0B1F5C),
    Color(0xFF3B82F6),
    Color(0xFFDBEAFE),
    Color(0xFF112659),
    Color(0xFFEFF5FF),
    Color(0xFFFFFFFF),
    Color(0xFFDFEBFF),
    Color(0xFF050B18),
    Color(0xFF0C162D),
    Color(0xFF132242),
    Color(0xFF0EA5E9),
    Color(0xFF38BDF8),
    Color(0xFFE0F2FE),
    Color(0xFF0D2A3F),
    Color(0xFF60A5FA),
    Color(0xFF38BDF8),
  ),
  royalAmethyst(
    'royal_amethyst',
    'Nébuleuse Violette',
    'Violet néon futuriste, orchidée et reflets cosmiques',
    Color(0xFF6D28D9),
    Color(0xFF2E1065),
    Color(0xFF8B5CF6),
    Color(0xFFEDE9FE),
    Color(0xFF261252),
    Color(0xFFF4F0FF),
    Color(0xFFFFFFFF),
    Color(0xFFE7DFFE),
    Color(0xFF090514),
    Color(0xFF140D29),
    Color(0xFF1F153D),
    Color(0xFFEC4899),
    Color(0xFFF472B6),
    Color(0xFFFCE7F3),
    Color(0xFF361229),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
  ),
  nordicSlate(
    'nordic_slate',
    'Glacier & Corail',
    'Contraste architectural épuré et énergie corail vif',
    Color(0xFF0F172A),
    Color(0xFF020617),
    Color(0xFF334155),
    Color(0xFFE2E8F0),
    Color(0xFF1E293B),
    Color(0xFFF3F6FA),
    Color(0xFFFFFFFF),
    Color(0xFFE5ECF3),
    Color(0xFF060A12),
    Color(0xFF0F1726),
    Color(0xFF182438),
    Color(0xFFF43F5E),
    Color(0xFFFB7185),
    Color(0xFFFFE4E6),
    Color(0xFF38131D),
    Color(0xFF38BDF8),
    Color(0xFFFB7185),
  ),
  cayorAmber(
    'cayor_amber',
    'Dunes & Or Sahel',
    'Terracotta solaire, chaleur safranée et sable doré',
    Color(0xFFC2410C),
    Color(0xFF5C1A05),
    Color(0xFFEA580C),
    Color(0xFFFFEDD5),
    Color(0xFF3B1508),
    Color(0xFFFFF5EC),
    Color(0xFFFFFFFF),
    Color(0xFFFDE7D3),
    Color(0xFF140905),
    Color(0xFF231109),
    Color(0xFF33190D),
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
    Color(0xFFFEF3C7),
    Color(0xFF332308),
    Color(0xFFFB923C),
    Color(0xFFFACC15),
  ),
  toubaOasis(
    'touba_oasis',
    'Lagon & Menthe',
    'Turquoise cristallin, fraîcheur aquatique et ambre doux',
    Color(0xFF0D9488),
    Color(0xFF044441),
    Color(0xFF14B8A6),
    Color(0xFFCCFBF1),
    Color(0xFF0B3533),
    Color(0xFFECFDF9),
    Color(0xFFFFFFFF),
    Color(0xFFD5F5EE),
    Color(0xFF041010),
    Color(0xFF0A1E1E),
    Color(0xFF102D2D),
    Color(0xFF06B6D4),
    Color(0xFF22D3EE),
    Color(0xFFCFFAFE),
    Color(0xFF0B2F38),
    Color(0xFF2DD4BF),
    Color(0xFF38BDF8),
  ),
  sunsetCoral(
    'sunset_coral',
    'Aurore Dakar',
    'Rubis-framboise vibrant, mangue solaire et lumière chaude',
    Color(0xFFBE123C),
    Color(0xFF5B081F),
    Color(0xFFE11D48),
    Color(0xFFFFE4E6),
    Color(0xFF3B0B19),
    Color(0xFFFFF1F4),
    Color(0xFFFFFFFF),
    Color(0xFFFCE0E6),
    Color(0xFF14050A),
    Color(0xFF240B13),
    Color(0xFF36111D),
    Color(0xFFF97316),
    Color(0xFFFB923C),
    Color(0xFFFFEDD5),
    Color(0xFF361B0A),
    Color(0xFFFB7185),
    Color(0xFFFB923C),
  );

  const SanctuaryPalette(
    this.code,
    this.labelFr,
    this.descriptionFr,
    this.primary,
    this.primaryDeep,
    this.primaryLight,
    this.primarySoft,
    this.primaryDarkSurface,
    this.canvasLight,
    this.elevatedLight,
    this.subtleFillLight,
    this.canvasDark,
    this.surfaceDark,
    this.elevatedDark,
    this.accent,
    this.accentBright,
    this.accentSoft,
    this.accentDarkSurface,
    this.meshOrbA,
    this.meshOrbB,
  );

  final String code;
  final String labelFr;
  final String descriptionFr;
  final Color primary;
  final Color primaryDeep;
  final Color primaryLight;
  final Color primarySoft;
  final Color primaryDarkSurface;
  final Color canvasLight;
  final Color elevatedLight;
  final Color subtleFillLight;
  final Color canvasDark;
  final Color surfaceDark;
  final Color elevatedDark;
  final Color accent;
  final Color accentBright;
  final Color accentSoft;
  final Color accentDarkSurface;
  final Color meshOrbA;
  final Color meshOrbB;

  static SanctuaryPalette fromCode(String? code) {
    return SanctuaryPalette.values.firstWhere(
      (p) => p.code == code,
      orElse: () => SanctuaryPalette.emeraldGold,
    );
  }
}

/// Distinct semantic pillar accents with vibrant jewel-tone gradients.
class YitteDomainAccents {
  const YitteDomainAccents._();

  static const Color spirituality = Color(0xFF059669);
  static const Color knowledge = Color(0xFF2563EB);
  static const Color challenges = Color(0xFFD97706);
  static const Color debates = Color(0xFF0891B2);
  static const Color english = Color(0xFF4F46E5);
  static const Color career = Color(0xFF0284C7);
  static const Color growth = Color(0xFF7C3AED);
  static const Color community = Color(0xFFE11D48);
}

/// Signature Architectural Sanctuary Palette (compat constants preserved):
class YitteColors {
  const YitteColors._();

  static const Color emerald = Color(0xFF0A4B3C);
  static const Color emeraldDeep = Color(0xFF062E24);
  static const Color emeraldLight = Color(0xFF217A63);
  static const Color emeraldSoft = Color(0xFFE3EFEA);
  static const Color emeraldDarkSurface = Color(0xFF102A23);

  static const Color ivory = Color(0xFFF6F2E9);
  static const Color ivoryElevated = Color(0xFFFFFCF5);
  static const Color stoneBorder = Color(0xFFE4DEC9);
  static const Color stoneMuted = Color(0xFFEBE5D6);
  static const Color cardLight = Color(0xFFFFFFFF);

  static const Color charcoal = Color(0xFF0D1412);
  static const Color cardDark = Color(0xFF15201D);
  static const Color cardDarkElevated = Color(0xFF1B2925);

  static const Color gold = Color(0xFFB88B32);
  static const Color goldBright = Color(0xFFDFB864);
  static const Color goldSoft = Color(0xFFF6ECD4);
  static const Color goldDarkSurface = Color(0xFF2B2313);

  static const Color inkDark = Color(0xFF0F172A);
  static const Color inkMuted = Color(0xFF475569);
  static const Color inkLight = Color(0xFFF8FAFC);
  static const Color inkLightMuted = Color(0xFF94A3B8);

  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
}

@immutable
class YitteSurfaceTokens extends ThemeExtension<YitteSurfaceTokens> {
  final Color canvas;
  final Color elevated;
  final Color subtleFill;
  final Color borderSubtle;
  final Color borderAccent;
  final Color goldAccent;
  final Color goldSurface;
  final Color shadowTint;
  final Color heroStart;
  final Color heroEnd;
  final Color meshOrbA;
  final Color meshOrbB;
  final UiVisualModel visualModel;
  final double cardRadius;

  const YitteSurfaceTokens({
    required this.canvas,
    required this.elevated,
    required this.subtleFill,
    required this.borderSubtle,
    required this.borderAccent,
    required this.goldAccent,
    required this.goldSurface,
    required this.shadowTint,
    required this.heroStart,
    required this.heroEnd,
    required this.meshOrbA,
    required this.meshOrbB,
    this.visualModel = UiVisualModel.glassLuxe,
    this.cardRadius = 26.0,
  });

  factory YitteSurfaceTokens.forPalette(
    SanctuaryPalette p, {
    required bool isDark,
    UiVisualModel model = UiVisualModel.glassLuxe,
  }) {
    final radius = model.cardRadius;
    if (isDark) {
      final canvas = switch (model) {
        UiVisualModel.editorialMinimal => const Color(0xFF090B0F),
        UiVisualModel.glassLuxe => p.canvasDark,
        UiVisualModel.dynamicCommunity => p.canvasDark,
        UiVisualModel.sanctuaryClassic => Color.lerp(p.canvasDark, const Color(0xFF0D1412), 0.35)!,
      };
      return YitteSurfaceTokens(
        canvas: canvas,
        elevated: model == UiVisualModel.glassLuxe
            ? Color.lerp(p.elevatedDark, Colors.white, 0.05) ?? p.elevatedDark
            : p.elevatedDark,
        subtleFill: p.primaryDarkSurface,
        borderSubtle: model == UiVisualModel.editorialMinimal
            ? Colors.white.withValues(alpha: 0.12)
            : p.meshOrbA.withValues(alpha: 0.22),
        borderAccent: p.accentBright.withValues(alpha: 0.48),
        goldAccent: p.accentBright,
        goldSurface: p.accentDarkSurface,
        shadowTint: Colors.black.withValues(alpha: 0.45),
        heroStart: p.primary,
        heroEnd: p.primaryDeep,
        meshOrbA: p.meshOrbA,
        meshOrbB: p.meshOrbB,
        visualModel: model,
        cardRadius: radius,
      );
    }

    final lightCanvas = switch (model) {
      UiVisualModel.editorialMinimal => const Color(0xFFFAFAFC),
      UiVisualModel.glassLuxe => p.canvasLight,
      UiVisualModel.dynamicCommunity =>
        Color.lerp(p.canvasLight, p.primarySoft, 0.38) ?? p.canvasLight,
      UiVisualModel.sanctuaryClassic => const Color(0xFFF6F2E9),
    };
    final lightElevated = model == UiVisualModel.sanctuaryClassic
        ? const Color(0xFFFFFCF5)
        : Colors.white;

    return YitteSurfaceTokens(
      canvas: lightCanvas,
      elevated: lightElevated,
      subtleFill: p.subtleFillLight,
      borderSubtle: model == UiVisualModel.editorialMinimal
          ? const Color(0xFFE2E8F0)
          : p.primary.withValues(alpha: 0.14),
      borderAccent: p.accent.withValues(alpha: 0.42),
      goldAccent: p.accent,
      goldSurface: p.accentSoft,
      shadowTint: model == UiVisualModel.editorialMinimal
          ? const Color(0x0D0F172A)
          : p.primary.withValues(alpha: 0.12),
      heroStart: p.primary,
      heroEnd: p.primaryDeep,
      meshOrbA: p.meshOrbA,
      meshOrbB: p.meshOrbB,
      visualModel: model,
      cardRadius: radius,
    );
  }

  static const lightTokens = YitteSurfaceTokens(
    canvas: Color(0xFFEEF7F4),
    elevated: Colors.white,
    subtleFill: Color(0xFFE0F1EB),
    borderSubtle: Color(0x22008564),
    borderAccent: Color(0x66E0A42A),
    goldAccent: Color(0xFFE0A42A),
    goldSurface: Color(0xFFFEF3D6),
    shadowTint: Color(0x1E008564),
    heroStart: Color(0xFF008564),
    heroEnd: Color(0xFF033B2D),
    meshOrbA: Color(0xFF34D399),
    meshOrbB: Color(0xFFFBBF24),
    visualModel: UiVisualModel.glassLuxe,
    cardRadius: 26.0,
  );

  static const darkTokens = YitteSurfaceTokens(
    canvas: Color(0xFF050E0C),
    elevated: Color(0xFF122620),
    subtleFill: Color(0xFF063729),
    borderSubtle: Color(0x3334D399),
    borderAccent: Color(0x66F6CA5B),
    goldAccent: Color(0xFFF6CA5B),
    goldSurface: Color(0xFF2B210E),
    shadowTint: Color(0x73000000),
    heroStart: Color(0xFF008564),
    heroEnd: Color(0xFF033B2D),
    meshOrbA: Color(0xFF34D399),
    meshOrbB: Color(0xFFFBBF24),
    visualModel: UiVisualModel.glassLuxe,
    cardRadius: 26.0,
  );

  @override
  YitteSurfaceTokens copyWith({
    Color? canvas,
    Color? elevated,
    Color? subtleFill,
    Color? borderSubtle,
    Color? borderAccent,
    Color? goldAccent,
    Color? goldSurface,
    Color? shadowTint,
    Color? heroStart,
    Color? heroEnd,
    Color? meshOrbA,
    Color? meshOrbB,
    UiVisualModel? visualModel,
    double? cardRadius,
  }) {
    return YitteSurfaceTokens(
      canvas: canvas ?? this.canvas,
      elevated: elevated ?? this.elevated,
      subtleFill: subtleFill ?? this.subtleFill,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderAccent: borderAccent ?? this.borderAccent,
      goldAccent: goldAccent ?? this.goldAccent,
      goldSurface: goldSurface ?? this.goldSurface,
      shadowTint: shadowTint ?? this.shadowTint,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      meshOrbA: meshOrbA ?? this.meshOrbA,
      meshOrbB: meshOrbB ?? this.meshOrbB,
      visualModel: visualModel ?? this.visualModel,
      cardRadius: cardRadius ?? this.cardRadius,
    );
  }

  @override
  YitteSurfaceTokens lerp(ThemeExtension<YitteSurfaceTokens>? other, double t) {
    if (other is! YitteSurfaceTokens) return this;
    return YitteSurfaceTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      subtleFill: Color.lerp(subtleFill, other.subtleFill, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderAccent: Color.lerp(borderAccent, other.borderAccent, t)!,
      goldAccent: Color.lerp(goldAccent, other.goldAccent, t)!,
      goldSurface: Color.lerp(goldSurface, other.goldSurface, t)!,
      shadowTint: Color.lerp(shadowTint, other.shadowTint, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      meshOrbA: Color.lerp(meshOrbA, other.meshOrbA, t)!,
      meshOrbB: Color.lerp(meshOrbB, other.meshOrbB, t)!,
      visualModel: t < 0.5 ? visualModel : other.visualModel,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static YitteSurfaceTokens tokensOf(BuildContext context) {
    return Theme.of(context).extension<YitteSurfaceTokens>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? YitteSurfaceTokens.darkTokens
            : YitteSurfaceTokens.lightTokens);
  }

  static TextTheme _buildTextTheme(
    Color primary,
    Color muted,
    UiVisualModel model,
  ) {
    final sansFamily = GoogleFonts.plusJakartaSans().fontFamily;
    final serifFamily = GoogleFonts.playfairDisplay().fontFamily;
    final displayFamily =
        (model == UiVisualModel.sanctuaryClassic) ? serifFamily : sansFamily;

    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: displayFamily,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: primary,
        height: 1.12,
      ),
      headlineLarge: TextStyle(
        fontFamily: displayFamily,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: primary,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFamily,
        fontSize: 21,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.35,
        color: primary,
        height: 1.22,
      ),
      titleLarge: TextStyle(
        fontFamily: sansFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: primary,
        height: 1.26,
      ),
      titleMedium: TextStyle(
        fontFamily: sansFamily,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
        color: primary,
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        fontFamily: sansFamily,
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.54,
      ),
      bodyMedium: TextStyle(
        fontFamily: sansFamily,
        fontSize: 13,
        color: muted,
        height: 1.46,
      ),
      labelLarge: TextStyle(
        fontFamily: sansFamily,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: sansFamily,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: muted,
      ),
    );
  }

  static ThemeData light([
    SanctuaryPalette palette = SanctuaryPalette.emeraldGold,
    UiVisualModel model = UiVisualModel.glassLuxe,
  ]) {
    final tokens = YitteSurfaceTokens.forPalette(
      palette,
      isDark: false,
      model: model,
    );
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: palette.primary,
      onPrimary: Colors.white,
      primaryContainer: palette.primarySoft,
      onPrimaryContainer: palette.primaryDeep,
      secondary: palette.accent,
      onSecondary: YitteColors.inkDark,
      secondaryContainer: palette.accentSoft,
      onSecondaryContainer: YitteColors.inkDark,
      surface: tokens.elevated,
      onSurface: YitteColors.inkDark,
      error: YitteColors.danger,
      onError: Colors.white,
    );
    final appBarFont = (model == UiVisualModel.sanctuaryClassic)
        ? GoogleFonts.playfairDisplay().fontFamily
        : GoogleFonts.plusJakartaSans().fontFamily;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.canvas,
      extensions: [tokens],
      textTheme: _buildTextTheme(YitteColors.inkDark, YitteColors.inkMuted, model),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: YitteColors.inkDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: appBarFont,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: YitteColors.inkDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderSubtle),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.elevated,
        selectedColor: palette.primarySoft,
        side: BorderSide(color: tokens.borderSubtle),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.borderSubtle,
        thickness: 1,
        space: 20,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: TextStyle(
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          side: BorderSide(color: palette.primary.withValues(alpha: 0.35), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primary, width: 1.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        height: 66,
        indicatorColor: palette.primarySoft,
      ),
    );
  }

  static ThemeData dark([
    SanctuaryPalette palette = SanctuaryPalette.emeraldGold,
    UiVisualModel model = UiVisualModel.glassLuxe,
  ]) {
    final tokens = YitteSurfaceTokens.forPalette(
      palette,
      isDark: true,
      model: model,
    );
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: palette.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: palette.primaryDarkSurface,
      onPrimaryContainer: palette.primarySoft,
      secondary: palette.accentBright,
      onSecondary: palette.canvasDark,
      secondaryContainer: palette.accentDarkSurface,
      onSecondaryContainer: palette.accentSoft,
      surface: tokens.elevated,
      onSurface: YitteColors.inkLight,
      error: const Color(0xFFFCA5A5),
      onError: const Color(0xFF450A0A),
    );
    final appBarFont = (model == UiVisualModel.sanctuaryClassic)
        ? GoogleFonts.playfairDisplay().fontFamily
        : GoogleFonts.plusJakartaSans().fontFamily;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.canvas,
      extensions: [tokens],
      textTheme: _buildTextTheme(YitteColors.inkLight, YitteColors.inkLightMuted, model),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: YitteColors.inkLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: appBarFont,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: YitteColors.inkLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderSubtle),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.elevated,
        selectedColor: palette.primaryDarkSurface,
        side: BorderSide(color: tokens.borderSubtle),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
        space: 20,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: TextStyle(
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.accentBright,
          side: BorderSide(color: palette.accentBright.withValues(alpha: 0.45), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.elevated.withValues(alpha: 0.9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.accentBright, width: 1.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        height: 66,
        indicatorColor: palette.primaryDarkSurface,
      ),
    );
  }

  static TextStyle arabicStyle({required Color color, double fontSize = 22}) {
    return TextStyle(
      fontFamily: GoogleFonts.amiri().fontFamily,
      fontSize: fontSize,
      height: 1.85,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }
}
