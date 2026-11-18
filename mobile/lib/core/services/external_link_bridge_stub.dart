import 'package:url_launcher/url_launcher.dart';

class ExternalLinkBridge {
  const ExternalLinkBridge._();

  static Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
