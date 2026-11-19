import 'package:material_ui/material_ui.dart';

/// Global font family constants (bundled locally in mobile/assets/fonts/).
class YitteFonts {
  const YitteFonts._();

  static const String display = 'PlayfairDisplay';
  static const String ui = 'PlusJakartaSans';
  static const String arabic = 'Amiri';
  static const List<String> fallback = <String>[
    'Amiri',
    'Noto Sans',
    'sans-serif',
  ];
}

/// User-selectable structural UI Models (4 editorial architectures — strictly flat, elevation 0).
enum UiVisualModel {
  editorialMinimal(
    'editorial_minimal',
    'Éditorial Tranchant',
    'Ivoire mat, filets 1px, typographie Playfair & icônes monochromes fines',
    12.0,
    false,
  ),
  sanctuaryClassic(
    'sanctuary_classic',
    'Classique Calligraphique',
    'Proportions classiques, sérifs affirmés et bordures dorées mates',
    10.0,
    false,
  ),
  glassLuxe(
    'glass_luxe',
    'Atelier Structuré',
    'Surfaces nettes, angles légèrement adoucis et contrastes maîtrisés',
    14.0,
    false,
  ),
  dynamicCommunity(
    'dynamic_community',
    'Revue Moderne',
    'Cartes à bordure soulignée et hiérarchie typographique marquée',
    12.0,
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
      orElse: () => UiVisualModel.editorialMinimal,
    );
  }
}

/// 8 curated editorial palettes (Light & Dark aware) led by the strict
/// signature 3-color Ivory / Charcoal + Emerald (#0B4635) & Matte Gold (#C5A059) system.
enum SanctuaryPalette {
  emeraldGold(
    'emerald_gold',
    'Ivoire & Émeraude',
    'Ivoire mat #F8F7F4, vert émeraude #0B4635 et or mat #C5A059',
    Color(0xFF0B4635),
    Color(0xFF072F23),
    Color(0xFF2F8F70),
    Color(0xFFEAF1EE),
    Color(0xFF13241E),
    Color(0xFFF8F7F4),
    Color(0xFFFFFFFF),
    Color(0xFFF1EFE9),
    Color(0xFF0E1110),
    Color(0xFF161B19),
    Color(0xFF161B19),
    Color(0xFFC5A059),
    Color(0xFFC5A059),
    Color(0xFFF7F2E6),
    Color(0xFF231F16),
    Color(0xFF0B4635),
    Color(0xFFC5A059),
  ),
  obsidianLuxe(
    'obsidian_luxe',
    'Encre & Or Mat',
    'Noir éditorial profond, papier ivoire et filets or mat',
    Color(0xFF141816),
    Color(0xFF0B0D0C),
    Color(0xFFC5A059),
    Color(0xFFECEAE4),
    Color(0xFF1E2220),
    Color(0xFFF8F7F4),
    Color(0xFFFFFFFF),
    Color(0xFFF0EEE8),
    Color(0xFF0E1110),
    Color(0xFF161B19),
    Color(0xFF161B19),
    Color(0xFFC5A059),
    Color(0xFFC5A059),
    Color(0xFFF7F2E6),
    Color(0xFF242016),
    Color(0xFF141816),
    Color(0xFFC5A059),
  ),
  medinaSapphire(
    'medina_sapphire',
    'Ardoise & Laiton',
    'Bleu-nuit sobre, papier mat et accents laiton',
    Color(0xFF1B365D),
    Color(0xFF10223B),
    Color(0xFF6B8FC5),
    Color(0xFFEBF0F6),
    Color(0xFF162233),
    Color(0xFFF8F7F4),
    Color(0xFFFFFFFF),
    Color(0xFFF0EFEA),
    Color(0xFF0E1114),
    Color(0xFF161A20),
    Color(0xFF161A20),
    Color(0xFFC5A059),
    Color(0xFFC5A059),
    Color(0xFFF7F2E6),
    Color(0xFF242016),
    Color(0xFF1B365D),
    Color(0xFFC5A059),
  ),
  royalAmethyst(
    'royal_amethyst',
    'Prune & Parchemin',
    'Bordeaux-prune feutré, ivoire et or mat',
    Color(0xFF4A2545),
    Color(0xFF2E162B),
    Color(0xFFA775A0),
    Color(0xFFF3ECF2),
    Color(0xFF231722),
    Color(0xFFF8F7F4),
    Color(0xFFFFFFFF),
    Color(0xFFF1EFEA),
    Color(0xFF100E11),
    Color(0xFF1A161B),
    Color(0xFF1A161B),
    Color(0xFFC5A059),
    Color(0xFFC5A059),
    Color(0xFFF7F2E6),
    Color(0xFF242016),
    Color(0xFF4A2545),
    Color(0xFFC5A059),
  ),
  nordicSlate(
    'nordic_slate',
    'Graphite Minimal',
    'Gris graphite architectural, papier pur et laiton sobre',
    Color(0xFF263238),
    Color(0xFF151D21),
    Color(0xFF8FA3AD),
    Color(0xFFECEFF1),
    Color(0xFF1B2226),
    Color(0xFFF8F7F4),
    Color(0xFFFFFFFF),
    Color(0xFFF0EFEA),
    Color(0xFF0E1110),
    Color(0xFF161B19),
    Color(0xFF161B19),
    Color(0xFFC5A059),
    Color(0xFFC5A059),
    Color(0xFFF7F2E6),
    Color(0xFF242016),
    Color(0xFF263238),
    Color(0xFFC5A059),
  ),
  cayorAmber(
    'cayor_amber',
    'Terre & Sahel',
    'Ocre brûlé sobre, papier ivoire et or sablé',
    Color(0xFF7A3E1D),
    Color(0xFF4D2611),
    Color(0xFFC8835B),
    Color(0xFFF6EEE9),
    Color(0xFF241A15),
    Color(0xFFF8F7F4),
    Color(0xFFFFFFFF),
    Color(0xFFF2EFEA),
    Color(0xFF110F0E),
    Color(0xFF1B1716),
    Color(0xFF1B1716),
    Color(0xFFC5A059),
    Color(0xFFC5A059),
    Color(0xFFF7F2E6),
    Color(0xFF242016),
    Color(0xFF7A3E1D),
    Color(0xFFC5A059),
  ),
  toubaOasis(
    'touba_oasis',
    'Cèdre & Ivoire',
    'Vert cèdre profond, lin naturel et filets or mat',
    Color(0xFF145249),
    Color(0xFF0B322C),
    Color(0xFF4BA194),
    Color(0xFFEAF3F1),
    Color(0xFF132220),
    Color(0xFFF8F7F4),
    Color(0xFFFFFFFF),
    Color(0xFFF0EFEA),
    Color(0xFF0E1110),
    Color(0xFF161B19),
    Color(0xFF161B19),
    Color(0xFFC5A059),
    Color(0xFFC5A059),
    Color(0xFFF7F2E6),
    Color(0xFF242016),
    Color(0xFF145249),
    Color(0xFFC5A059),
  ),
  sunsetCoral(
    'sunset_coral',
    'Bordeaux & Or',
    'Bordeaux littéraire, ivoire mat et or discret',
    Color(0xFF6B2230),
    Color(0xFF42141D),
    Color(0xFFC46D7D),
    Color(0xFFF6ECEE),
    Color(0xFF231619),
    Color(0xFFF8F7F4),
    Color(0xFFFFFFFF),
    Color(0xFFF1EFEA),
    Color(0xFF110E0F),
    Color(0xFF1B1617),
    Color(0xFF1B1617),
    Color(0xFFC5A059),
    Color(0xFFC5A059),
    Color(0xFFF7F2E6),
    Color(0xFF242016),
    Color(0xFF6B2230),
    Color(0xFFC5A059),
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

/// Strict monochrome editorial accents — ONLY Emerald (#0B4635) and Matte Gold (#C5A059).
/// Zero multicolor rainbow badges.
class YitteDomainAccents {
  const YitteDomainAccents._();

  static const Color spirituality = YitteColors.emerald;
  static const Color knowledge = YitteColors.emerald;
  static const Color challenges = YitteColors.gold;
  static const Color debates = YitteColors.emerald;
  static const Color english = YitteColors.emerald;
  static const Color career = YitteColors.emerald;
  static const Color growth = YitteColors.gold;
  static const Color community = YitteColors.emerald;
}

/// Strict 3-color editorial palette tokens:
/// Light: Canvas #F8F7F4, Surface #FFFFFF, Border #E5E2DA, Ink #141816
/// Dark:  Canvas #0E1110, Surface #161B19, Border #262E2B, Ink #F2F0EA
/// Accents ONLY: Emerald #0B4635 & Matte Gold #C5A059.
class YitteColors {
  const YitteColors._();

  static const Color emerald = Color(0xFF0B4635);
  static const Color emeraldDeep = Color(0xFF072F23);
  static const Color emeraldLight = Color(0xFF2F8F70);
  static const Color emeraldSoft = Color(0xFFEAF1EE);
  static const Color emeraldDarkSurface = Color(0xFF13241E);

  static const Color ivory = Color(0xFFF8F7F4);
  static const Color ivoryElevated = Color(0xFFFFFFFF);
  static const Color stoneBorder = Color(0xFFE5E2DA);
  static const Color stoneMuted = Color(0xFFF1EFE9);
  static const Color cardLight = Color(0xFFFFFFFF);

  static const Color charcoal = Color(0xFF0E1110);
  static const Color cardDark = Color(0xFF161B19);
  static const Color cardDarkElevated = Color(0xFF161B19);
  static const Color borderDark = Color(0xFF262E2B);

  static const Color gold = Color(0xFFC5A059);
  static const Color goldBright = Color(0xFFC5A059);
  static const Color goldSoft = Color(0xFFF7F2E6);
  static const Color goldDarkSurface = Color(0xFF231F16);

  static const Color inkDark = Color(0xFF141816);
  static const Color inkMuted = Color(0xFF5A625D);
  static const Color inkLight = Color(0xFFF2F0EA);
  static const Color inkLightMuted = Color(0xFF9BA39E);

  static const Color danger = Color(0xFF9E2A2B);
  static const Color success = Color(0xFF0B4635);
  static const Color warning = Color(0xFFC5A059);
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
    this.visualModel = UiVisualModel.editorialMinimal,
    this.cardRadius = 12.0,
  });

  factory YitteSurfaceTokens.forPalette(
    SanctuaryPalette p, {
    required bool isDark,
    UiVisualModel model = UiVisualModel.editorialMinimal,
  }) {
    final radius = model.cardRadius;
    if (isDark) {
      return YitteSurfaceTokens(
        canvas: p.canvasDark,
        elevated: p.surfaceDark,
        subtleFill: p.primaryDarkSurface,
        borderSubtle: YitteColors.borderDark,
        borderAccent: p.accent.withValues(alpha: 0.45),
        goldAccent: p.accent,
        goldSurface: p.accentDarkSurface,
        shadowTint: Colors.transparent,
        heroStart: p.primary,
        heroEnd: p.primaryDeep,
        meshOrbA: p.meshOrbA,
        meshOrbB: p.meshOrbB,
        visualModel: model,
        cardRadius: radius,
      );
    }

    return YitteSurfaceTokens(
      canvas: p.canvasLight,
      elevated: p.elevatedLight,
      subtleFill: p.subtleFillLight,
      borderSubtle: YitteColors.stoneBorder,
      borderAccent: p.accent.withValues(alpha: 0.48),
      goldAccent: p.accent,
      goldSurface: p.accentSoft,
      shadowTint: Colors.transparent,
      heroStart: p.primary,
      heroEnd: p.primaryDeep,
      meshOrbA: p.meshOrbA,
      meshOrbB: p.meshOrbB,
      visualModel: model,
      cardRadius: radius,
    );
  }

  static const lightTokens = YitteSurfaceTokens(
    canvas: YitteColors.ivory,
    elevated: YitteColors.cardLight,
    subtleFill: YitteColors.stoneMuted,
    borderSubtle: YitteColors.stoneBorder,
    borderAccent: Color(0x7AC5A059),
    goldAccent: YitteColors.gold,
    goldSurface: YitteColors.goldSoft,
    shadowTint: Colors.transparent,
    heroStart: YitteColors.emerald,
    heroEnd: YitteColors.emeraldDeep,
    meshOrbA: YitteColors.emerald,
    meshOrbB: YitteColors.gold,
    visualModel: UiVisualModel.editorialMinimal,
    cardRadius: 12.0,
  );

  static const darkTokens = YitteSurfaceTokens(
    canvas: YitteColors.charcoal,
    elevated: YitteColors.cardDark,
    subtleFill: YitteColors.emeraldDarkSurface,
    borderSubtle: YitteColors.borderDark,
    borderAccent: Color(0x73C5A059),
    goldAccent: YitteColors.gold,
    goldSurface: YitteColors.goldDarkSurface,
    shadowTint: Colors.transparent,
    heroStart: YitteColors.emerald,
    heroEnd: YitteColors.emeraldDeep,
    meshOrbA: YitteColors.emerald,
    meshOrbB: YitteColors.gold,
    visualModel: UiVisualModel.editorialMinimal,
    cardRadius: 12.0,
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

  static TextTheme _buildTextTheme(Color primary, Color muted) {
    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: YitteFonts.display,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
        height: 1.16,
      ),
      headlineLarge: TextStyle(
        fontFamily: YitteFonts.display,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: primary,
        height: 1.18,
      ),
      headlineMedium: TextStyle(
        fontFamily: YitteFonts.display,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: primary,
        height: 1.24,
      ),
      titleLarge: TextStyle(
        fontFamily: YitteFonts.display,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: primary,
        height: 1.28,
      ),
      titleMedium: TextStyle(
        fontFamily: YitteFonts.ui,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: primary,
        height: 1.32,
      ),
      titleSmall: TextStyle(
        fontFamily: YitteFonts.ui,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        fontFamily: YitteFonts.ui,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.56,
      ),
      bodyMedium: TextStyle(
        fontFamily: YitteFonts.ui,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.48,
      ),
      bodySmall: TextStyle(
        fontFamily: YitteFonts.ui,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.44,
      ),
      labelLarge: TextStyle(
        fontFamily: YitteFonts.ui,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: YitteFonts.ui,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: muted,
      ),
      labelSmall: TextStyle(
        fontFamily: YitteFonts.ui,
        fontFamilyFallback: YitteFonts.fallback,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: muted,
      ),
    );
  }

  static ThemeData light([
    SanctuaryPalette palette = SanctuaryPalette.emeraldGold,
    UiVisualModel model = UiVisualModel.editorialMinimal,
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
      outline: tokens.borderSubtle,
      error: YitteColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: YitteFonts.ui,
      fontFamilyFallback: YitteFonts.fallback,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.canvas,
      shadowColor: Colors.transparent,
      extensions: [tokens],
      textTheme: _buildTextTheme(YitteColors.inkDark, YitteColors.inkMuted),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: YitteColors.inkDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: YitteFonts.display,
          fontFamilyFallback: YitteFonts.fallback,
          fontSize: 18.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: YitteColors.inkDark,
        ),
        shape: Border(bottom: BorderSide(color: tokens.borderSubtle, width: 1)),
      ),
      cardTheme: CardThemeData(
        color: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.elevated,
        selectedColor: palette.primarySoft,
        side: BorderSide(color: tokens.borderSubtle, width: 1),
        elevation: 0,
        pressElevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: const TextStyle(
          fontFamily: YitteFonts.ui,
          fontFamilyFallback: YitteFonts.fallback,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: YitteColors.inkDark,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(
            fontFamily: YitteFonts.ui,
            fontFamilyFallback: YitteFonts.fallback,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: BorderSide(color: tokens.borderSubtle, width: 1),
          backgroundColor: tokens.elevated,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: YitteFonts.ui,
            fontFamilyFallback: YitteFonts.fallback,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: const TextStyle(
            fontFamily: YitteFonts.ui,
            fontFamilyFallback: YitteFonts.fallback,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          side: WidgetStatePropertyAll(
            BorderSide(color: tokens.borderSubtle, width: 1),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.elevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.primary, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: palette.primarySoft,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark([
    SanctuaryPalette palette = SanctuaryPalette.emeraldGold,
    UiVisualModel model = UiVisualModel.editorialMinimal,
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
      outline: tokens.borderSubtle,
      error: const Color(0xFFE07A7A),
      onError: const Color(0xFF2B0E0E),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: YitteFonts.ui,
      fontFamilyFallback: YitteFonts.fallback,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.canvas,
      shadowColor: Colors.transparent,
      extensions: [tokens],
      textTheme: _buildTextTheme(YitteColors.inkLight, YitteColors.inkLightMuted),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: YitteColors.inkLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: YitteFonts.display,
          fontFamilyFallback: YitteFonts.fallback,
          fontSize: 18.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: YitteColors.inkLight,
        ),
        shape: Border(bottom: BorderSide(color: tokens.borderSubtle, width: 1)),
      ),
      cardTheme: CardThemeData(
        color: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.elevated,
        selectedColor: palette.primaryDarkSurface,
        side: BorderSide(color: tokens.borderSubtle, width: 1),
        elevation: 0,
        pressElevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: const TextStyle(
          fontFamily: YitteFonts.ui,
          fontFamilyFallback: YitteFonts.fallback,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: YitteColors.inkLight,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.borderSubtle,
        thickness: 1,
        space: 20,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: YitteColors.inkLight,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(
            fontFamily: YitteFonts.ui,
            fontFamilyFallback: YitteFonts.fallback,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.accentBright,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: BorderSide(color: tokens.borderSubtle, width: 1),
          backgroundColor: tokens.elevated,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: YitteFonts.ui,
            fontFamilyFallback: YitteFonts.fallback,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accentBright,
          textStyle: const TextStyle(
            fontFamily: YitteFonts.ui,
            fontFamilyFallback: YitteFonts.fallback,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          side: WidgetStatePropertyAll(
            BorderSide(color: tokens.borderSubtle, width: 1),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.elevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.accentBright, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: palette.primaryDarkSurface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: palette.primary,
        foregroundColor: YitteColors.inkLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextStyle arabicStyle({required Color color, double fontSize = 22}) {
    return TextStyle(
      fontFamily: YitteFonts.arabic,
      fontFamilyFallback: YitteFonts.fallback,
      fontSize: fontSize,
      height: 1.85,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }
}
