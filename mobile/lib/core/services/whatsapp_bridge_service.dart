/// Utilitaires concrets pour le pont officiel WhatsApp (liens d’invitation,
/// partage direct wa.me et analyse fidèle d’exports .txt WhatsApp).
class WhatsAppParsedMessage {
  final String sender;
  final String body;

  const WhatsAppParsedMessage({
    required this.sender,
    required this.body,
  });
}

class WhatsAppBridgeService {
  const WhatsAppBridgeService._();

  /// Valide uniquement les liens officiels HTTPS WhatsApp (`chat.whatsapp.com` ou `wa.me`).
  static String? normalizeInviteUrl(String? raw) {
    final clean = raw?.trim() ?? '';
    if (clean.isEmpty) return null;
    final uri = Uri.tryParse(clean);
    if (uri == null || uri.scheme != 'https') return null;
    final host = uri.host.toLowerCase();
    if (host == 'chat.whatsapp.com' ||
        host == 'wa.me' ||
        host == 'www.whatsapp.com' ||
        host == 'api.whatsapp.com') {
      return uri.toString();
    }
    return null;
  }

  /// Construit un lien officiel `https://wa.me/?text=...` prêt pour partage Web/Android/iOS.
  static String buildShareUrl(String message, {String? groupInviteUrl}) {
    final buffer = StringBuffer(message.trim());
    final cleanInvite = normalizeInviteUrl(groupInviteUrl);
    if (cleanInvite != null) {
      buffer.write('\n\nLien du groupe : $cleanInvite');
    }
    return 'https://wa.me/?text=${Uri.encodeComponent(buffer.toString())}';
  }

  /// Parse fidèlement un fichier d’export WhatsApp `.txt` (formats iOS `[DD/MM/YYYY, HH:MM]`
  /// et Android `DD/MM/YYYY, HH:MM - Auteur: message`) sans inventer ni modifier le contenu.
  static List<WhatsAppParsedMessage> parseWhatsAppChatExport(String rawText) {
    final lines = rawText.split(RegExp(r'\r?\n'));
    final iosPattern = RegExp(
      r'^\[?\d{1,2}[\/.-]\d{1,2}[\/.-]\d{2,4}[,\s]+\d{1,2}:\d{2}(?::\d{2})?(?:\s?[AP]M)?\]\s+([^:]{1,80}):\s+(.+)$',
    );
    final androidPattern = RegExp(
      r'^\d{1,2}[\/.-]\d{1,2}[\/.-]\d{2,4}[,\s]+\d{1,2}:\d{2}(?::\d{2})?(?:\s?[AP]M)?\s*-\s*([^:]{1,80}):\s+(.+)$',
    );

    final parsed = <WhatsAppParsedMessage>[];
    for (final line in lines) {
      final clean = line.trim();
      if (clean.isEmpty) continue;
      final match = iosPattern.firstMatch(clean) ?? androidPattern.firstMatch(clean);
      if (match != null) {
        final sender = match.group(1)!.trim();
        final body = match.group(2)!.trim();
        if (_isSystemNotice(body)) continue;
        parsed.add(WhatsAppParsedMessage(sender: sender, body: body));
      } else if (parsed.isNotEmpty && !clean.startsWith('‎')) {
        // Continuation multi-ligne d’un message réel existant
        final last = parsed.removeLast();
        parsed.add(
          WhatsAppParsedMessage(
            sender: last.sender,
            body: '${last.body}\n$clean',
          ),
        );
      }
    }
    if (parsed.length > 50) {
      return parsed.sublist(parsed.length - 50);
    }
    return parsed;
  }

  static bool _isSystemNotice(String body) {
    final lower = body.toLowerCase();
    return lower.contains('chiffrés de bout en bout') ||
        lower.contains('end-to-end encrypted') ||
        lower == '<médias omis>' ||
        lower == '<media omitted>';
  }
}
