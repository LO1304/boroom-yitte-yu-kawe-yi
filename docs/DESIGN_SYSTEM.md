# Design System — BOROOM YITTÉ YU KAWÉ YI

## Identité visuelle
Inspirée des plateformes éducatives modernes et de l'édition islamique contemporaine sobre :

| Token | Mode Clair | Mode Sombre | Usage |
|---|---|---|---|
| **Primary (Deep Emerald)** | `#0B4F3F` | `#1C7C64` | En-têtes, actions principales, badges d'excellence |
| **Primary Container** | `#DDF0E9` | `#0F372C` | Cartes mises en avant, états actifs |
| **Background (Ivory / Charcoal)** | `#FAF7F0` | `#111615` | Fond principal chaleureux ou sombre reposant |
| **Surface Card** | `#FFFFFF` | `#19211F` | Cartes modulaires, fiches de défis, résumés |
| **Accent (Warm Gold)** | `#C89B3C` | `#DFB65D` | Ornements éditoriaux, distinctions éducatives, citations |
| **Text Primary** | `#14231F` | `#F3EFE6` | Titres et corps de texte à fort contraste |
| **Text Secondary** | `#52635E` | `#AAB8B3` | Métadonnées, sous-titres, horodatages |

## Composants Sanctuaire (`mobile/lib/core/theme/app_theme.dart` & `mobile/lib/core/widgets/design_system.dart`)
- **`YitteSurfaceTokens` (`ThemeExtension`)** : sémantique unifiée clair/sombre (`canvas`, `surfaceElevated`, `subtleFill`, `borderSubtle`, `borderAccent`, `goldSurface`, `goldAccent`).
- **`SanctuaryGeometryPainter`** : motif géométrique étoilé discret en arrière-plan des bannières éditoriales et du `SplashScreen`.
- **Motion & ergonomie** : `YitteReveal` (animations échelonnées respectant `MediaQuery.disableAnimations`), `yitteTransitionPage`, `YitteSurfaceCard`, `YitteStatusPill`, `YitteEmptyState` et `YitteLoadingBanner`.

## Typographie & Multilingue
- **Français (primaire)**, **Anglais**, **Arabe** et **Wolof** (`app_localizations.dart`) : `Plus Jakarta Sans` pour la lisibilité d'interface, `Playfair Display` pour les titres éditoriaux et `Amiri` pour les textes et invocations arabes avec direction native `TextDirection.rtl`.
- Rayons de courbure doux (`18px` cartes, `14px` boutons/champs, `999px` pilules), contraste maîtrisé clair/sombre et zéro superposition sur format mobile `390×844`.
