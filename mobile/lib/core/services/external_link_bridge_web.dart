import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

class ExternalLinkBridge {
  const ExternalLinkBridge._();

  static Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return false;
    }
    try {
      _window.callMethod(
        'open'.toJS,
        url.trim().toJS,
        '_blank'.toJS,
        'noopener,noreferrer'.toJS,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
