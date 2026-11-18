import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/deep_link_service.dart';
import '../core/services/notification_service.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'state/app_providers.dart';

class BoroomYitteApp extends ConsumerStatefulWidget {
  final bool enablePlatformHooks;
  const BoroomYitteApp({super.key, this.enablePlatformHooks = true});

  @override
  ConsumerState<BoroomYitteApp> createState() => _BoroomYitteAppState();
}

class _BoroomYitteAppState extends ConsumerState<BoroomYitteApp> {
  @override
  void initState() {
    super.initState();
    if (widget.enablePlatformHooks) {
      NotificationService.instance.initialize(
        onNotificationTap: (deepLink) {
          if (deepLink != null && deepLink.isNotEmpty) {
            final route = DeepLinkService.mapUriToRoute(Uri.parse(deepLink));
            ref.read(appRouterProvider).go(route);
          }
        },
      );
      DeepLinkService.instance.startListening((routePath) {
        ref.read(appRouterProvider).go(routePath);
      });
      _checkDailyTasbihLaunch();
    }
  }

  Future<void> _checkDailyTasbihLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final openTasbih = prefs.getBool('yitte_open_tasbih_launch') ?? false;
    if (openTasbih && mounted) {
      ref.read(appRouterProvider).go('/zikr');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final palette = ref.watch(themePaletteProvider);
    final visualModel = ref.watch(uiVisualModelProvider);
    final lang = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'BOROOM YITTÉ YU KAWÉ YI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(palette, visualModel),
      darkTheme: AppTheme.dark(palette, visualModel),
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 380),
      themeAnimationCurve: Curves.easeInOutCubic,
      locale: lang.materialLocale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: lang.direction,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
