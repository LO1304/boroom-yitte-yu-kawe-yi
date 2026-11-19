import 'package:material_ui/material_ui.dart';

/// Supported language codes across the ecosystem:
/// - `fr`: Primary community language (French)
/// - `en`: English
/// - `ar`: Arabic (with native RTL layout direction)
/// - `wo`: Wolof (mapped gracefully inside UI & Material fallback to French)
enum AppLanguage {
  fr('fr', 'Français', TextDirection.ltr),
  en('en', 'English', TextDirection.ltr),
  ar('ar', 'العربية', TextDirection.rtl),
  wo('wo', 'Wolof', TextDirection.ltr);

  const AppLanguage(this.code, this.label, this.direction);
  final String code;
  final String label;
  final TextDirection direction;

  Locale get materialLocale {
    // Material/Cupertino stock delegates support fr/en/ar natively; wo inherits fr widgets cleanly
    switch (this) {
      case AppLanguage.wo:
        return const Locale('fr');
      default:
        return Locale(code);
    }
  }

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.fr,
    );
  }
}

class AppStrings {
  const AppStrings(this.lang);
  final AppLanguage lang;

  String t(String key) {
    return _localized[lang.code]?[key] ??
        _localized['fr']?[key] ??
        key;
  }

  static String categoryLabel(String code) {
    return switch (code) {
      'islamic_thought' => 'Pensée islamique',
      'philosophy' => 'Philosophie',
      'spirituality' => 'Spiritualité',
      'ethics' => 'Éthique',
      'history' => 'Histoire',
      'science' => 'Sciences',
      'technology' => 'Technologie',
      'logic' => 'Logique',
      'society' => 'Société',
      'general_knowledge' => 'Culture générale',
      _ => code,
    };
  }

  static String difficultyLabel(String code) {
    return switch (code) {
      'beginner' || 'easy' => 'Débutant',
      'intermediate' => 'Intermédiaire',
      'advanced' || 'hard' => 'Avancé',
      _ => code,
    };
  }

  static String positionLabel(String code) {
    return switch (code.toLowerCase()) {
      'for' => 'Pour',
      'against' => 'Contre',
      'nuanced' => 'Nuancé',
      _ => code,
    };
  }

  static const Map<String, Map<String, String>> _localized = {
    'fr': {
      'app_title': 'BOROOM YITTÉ YU KAWÉ YI',
      'tagline': "S'élever individuellement, grandir collectivement.",
      'nav_home': 'Accueil',
      'nav_reflections': 'Réflexions',
      'nav_challenges': 'Défis',
      'nav_learning': 'Apprendre',
      'nav_community': 'Communauté',
      'home_welcome': 'Assalāmu ʿalaykum',
      'quick_modules': 'Écosystème Boroom Yitté',
      'face_a_face': 'Yitté Face-à-Face',
      'quiz_arena': 'Yitté Quiz Arena',
      'zikr': 'Yitté Zikr',
      'english_club': 'Yitté English Club',
      'professional': 'Yitté Professionnel',
      'personal_growth': 'Développement Personnel',
      'admin_console': 'Administration',
      'settings': 'Paramètres',
      'offline_badge': 'Cercle Privé',
      'cloud_badge': 'Supabase Connecté',
      'zikr_no_rank_notice':
          'Espace spirituel apaisé : aucun classement ni score de piété.',
      'private_growth_notice':
          'Espace strictement privé : vos notes et réflexions personnelles restent confidentielles.',
      'ai_fairness_notice':
          'Évaluation aveugle à l’accent, l’identité et la croyance — fondée sur la qualité du raisonnement.',
      'export_pdf': 'Exporter en PDF',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'submit': 'Soumettre',
      'documents_title': 'Bibliothèque Documentaire',
      'extra_groupe_title': 'Extra Groupe • Rencontres Mensuelles',
      'notifications_title': 'Notifications & Alertes',
      'whatsapp_group': 'Groupe WhatsApp Communautaire',
      'full_name_access': 'Accès par Nom Complet',
      'restricted_group_only': 'Accès réservé aux membres du groupe',
    },
    'en': {
      'app_title': 'BOROOM YITTÉ YU KAWÉ YI',
      'tagline': 'Elevate individually, grow collectively.',
      'nav_home': 'HOME',
      'nav_reflections': 'REFLECTIONS',
      'nav_challenges': 'CHALLENGES',
      'nav_learning': 'LEARNING',
      'nav_community': 'COMMUNITY',
      'home_welcome': 'Peace be upon you',
      'quick_modules': 'Boroom Yitté Ecosystem',
      'face_a_face': 'Yitté Face-à-Face',
      'quiz_arena': 'Yitté Quiz Arena',
      'zikr': 'Yitté Zikr',
      'english_club': 'Yitté English Club',
      'professional': 'Yitté Professional',
      'personal_growth': 'Personal Growth',
      'admin_console': 'Administration',
      'settings': 'Settings',
      'offline_badge': 'Private Circle',
      'cloud_badge': 'Supabase Connected',
      'zikr_no_rank_notice':
          'Peaceful spiritual space: no rankings, scores, or piety badges.',
      'private_growth_notice':
          'Strictly private space: your personal notes and reflections stay confidential.',
      'ai_fairness_notice':
          'Evaluated blindly to accent, identity, and personal beliefs — focused purely on reasoning.',
      'export_pdf': 'Export PDF',
      'save': 'Save',
      'cancel': 'Cancel',
      'submit': 'Submit',
      'documents_title': 'Document Library',
      'extra_groupe_title': 'Extra Groupe • Monthly Encounters',
      'notifications_title': 'Notifications & Alerts',
      'whatsapp_group': 'Community WhatsApp Group',
      'full_name_access': 'Full-Name Member Login',
      'restricted_group_only': 'Access reserved for verified group members',
    },
    'ar': {
      'app_title': 'بوروم ييتي يو كاوي يي',
      'tagline': 'نرتقي فردياً، وننمو جماعياً.',
      'nav_home': 'الرئيسية',
      'nav_reflections': 'تأملات',
      'nav_challenges': 'تحديات',
      'nav_learning': 'التعلّم',
      'nav_community': 'المجتمع',
      'home_welcome': 'السلام عليكم',
      'quick_modules': 'منظومة بوروم ييتي',
      'face_a_face': 'مناظرة وجهاً لوجه',
      'quiz_arena': 'ساحة المسابقات',
      'zikr': 'مجالس الذكر',
      'english_club': 'نادي الإنجليزية',
      'professional': 'التطوير المهني',
      'personal_growth': 'التطوير الذاتي',
      'admin_console': 'الإدارة',
      'settings': 'الإعدادات',
      'offline_badge': 'الدائرة الخاصة',
      'cloud_badge': 'متصل بـ Supabase',
      'zikr_no_rank_notice':
          'فضاء روحي هادئ: لا ترتيب ولا نقاط تقوى ولا مقارنة بين الأعضاء.',
      'private_growth_notice':
          'فضاء خاص تماماً: تبقى ملاحظاتك وتأملاتك الشخصية سرية.',
      'ai_fairness_notice':
          'تقييم موضوعي لجودة الاستدلال دون أي تحيز للهوية أو اللهجة أو الرأي.',
      'export_pdf': 'تصدير PDF',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'submit': 'إرسال',
      'documents_title': 'المكتبة الوثائقية',
      'extra_groupe_title': 'لقاءات إكسترا غروب الشهرية',
      'notifications_title': 'الإشعارات والتنبيهات',
      'whatsapp_group': 'مجموعة واتساب للمجتمع',
      'full_name_access': 'الدخول بالاسم الكامل للأعضاء',
      'restricted_group_only': 'الوصول محصور لأعضاء المجموعة فقط',
    },
    'wo': {
      'app_title': 'BOROOM YITTÉ YU KAWÉ YI',
      'tagline': 'Yéeg sa bopp, màggandoo ci mbooloo mi.',
      'nav_home': 'KËR GI',
      'nav_reflections': 'XALAAT YI',
      'nav_challenges': 'JÀNGORO',
      'nav_learning': 'NJÀNG MI',
      'nav_community': 'MBOOLOO MI',
      'home_welcome': 'As-salāmu ʿalaykum',
      'quick_modules': 'Kër Boroom Yitté',
      'face_a_face': 'Yitté Face-à-Face',
      'quiz_arena': 'Yitté Quiz Arena',
      'zikr': 'Yitté Zikr',
      'english_club': 'Yitté English Club',
      'professional': 'Liggéey & Xam-xam',
      'personal_growth': 'Yar sa bopp',
      'admin_console': 'Njiit yi',
      'settings': 'Paramètre yi',
      'offline_badge': 'Cercle Privé',
      'cloud_badge': 'Supabase Connecté',
      'zikr_no_rank_notice':
          'Bérabu Zikr bi amul classement wala note ngir diine.',
      'private_growth_notice':
          'Sa xalaat yu bopp kenn du ko gis, yaa ko moom.',
      'ai_fairness_notice':
          'Nattukaay bi xalaat wi rekk lay seet, du seet làkk wala diine.',
      'export_pdf': 'PDF',
      'save': 'Denc',
      'cancel': 'Neenal',
      'submit': 'Yónne',
      'documents_title': 'Dencukaayu Téere yi',
      'extra_groupe_title': 'Ndaje Extra Groupe',
      'notifications_title': 'Yéene yi',
      'whatsapp_group': 'Mbooloo WhatsApp bi',
      'full_name_access': 'Dugg ak sa tur wi mat',
      'restricted_group_only': 'Mbokki mbooloo mi rekk ñoo fi mëna dugg',
    },
  };
}
