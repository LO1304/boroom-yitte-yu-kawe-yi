import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> startListening(void Function(String routePath) onNavigate) async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        onNavigate(mapUriToRoute(initial));
      }
      _sub = _appLinks.uriLinkStream.listen((uri) {
        onNavigate(mapUriToRoute(uri));
      });
    } catch (e) {
      debugPrint('Deep link listener not active in test/headless mode: $e');
    }
  }

  static String mapUriToRoute(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path;
    if (uri.scheme == 'boroomyitte') {
      switch (host) {
        case 'zikr':
          return '/zikr';
        case 'debates':
          return '/debates';
        case 'quiz':
          return '/quiz-arena';
        case 'english':
          return '/english-club';
        case 'professional':
          return '/professional';
        case 'personal-growth':
          return '/personal-growth';
        case 'admin':
          return '/admin';
        default:
          return '/';
      }
    }
    return path.isEmpty ? '/' : path;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }
}
