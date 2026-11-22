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
      buffer.write('\n\nRejoindre le cercle : $cleanInvite');
    }
    return 'https://wa.me/?text=${Uri.encodeComponent(buffer.toString())}';
  }

  /// Met en forme une question ou contribution individuelle d'un membre
  /// avec la typographie native WhatsApp (*gras*, _italique_, > citation).
  static String formatSingleMemberQuestion({
    required String subjectTitle,
    required String questionText,
    String? authorName,
    String? contextLabel,
    String? answerText,
  }) {
    final cleanSubject = subjectTitle.trim();
    final cleanQuestion = questionText.trim().replaceAll('\n', '\n> ');
    final cleanAuthor = (authorName ?? '').trim();
    final cleanContext = (contextLabel ?? '').trim();
    final cleanAnswer = (answerText ?? '').trim();

    final buf = StringBuffer()
      ..writeln('*BOROOM YITTÉ YU KAWÉ YI*');
    if (cleanContext.isNotEmpty) {
      buf.writeln('_${cleanContext}_');
    }
    buf
      ..writeln('*Sujet :* $cleanSubject')
      ..writeln('━━━━━━━━━━━━━━');
    if (cleanAuthor.isNotEmpty) {
      buf.writeln('*Question de $cleanAuthor :*');
    } else {
      buf.writeln('*Question sur le sujet :*');
    }
    buf.writeln('> « $cleanQuestion »');
    if (cleanAnswer.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('*Élément de réponse :*')
        ..writeln('_${cleanAnswer}_');
    }
    buf
      ..writeln('━━━━━━━━━━━━━━')
      ..write('_Réagissez et partagez votre regard dans le groupe._');
    return buf.toString();
  }

  /// Met en forme toutes les questions / contributions posées par les membres
  /// sur un même sujet en un bulletin WhatsApp fluide, structuré et cohérent.
  static String formatTopicQuestionsDigest({
    required String subjectTitle,
    required List<({String? author, String text, String? answer})> items,
    String? contextLabel,
    String? subtitle,
  }) {
    final cleanSubject = subjectTitle.trim();
    final cleanContext = (contextLabel ?? '').trim();
    final cleanSubtitle = (subtitle ?? '').trim();

    final buf = StringBuffer()
      ..writeln('*BOROOM YITTÉ YU KAWÉ YI*');
    if (cleanContext.isNotEmpty) {
      buf.writeln('_${cleanContext}_');
    }
    buf.writeln('*Sujet :* $cleanSubject');
    if (cleanSubtitle.isNotEmpty) {
      buf.writeln('_${cleanSubtitle}_');
    }
    buf.writeln('━━━━━━━━━━━━━━');

    if (items.isEmpty) {
      buf.writeln('_Les questions des membres sont ouvertes — envoyez la vôtre !_');
    } else {
      buf
        ..writeln('*Questions & échanges (${items.length}) :*')
        ..writeln();
      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final author = (it.author ?? '').trim();
        final body = it.text.trim().replaceAll('\n', '\n> ');
        if (author.isNotEmpty) {
          buf.writeln('*${i + 1}. $author*');
        } else {
          buf.writeln('*Question ${i + 1}*');
        }
        buf.writeln('> $body');
        final ans = (it.answer ?? '').trim();
        if (ans.isNotEmpty) {
          buf.writeln('_↳ Réponse : $ans _');
        }
        if (i < items.length - 1) buf.writeln();
      }
    }
    buf
      ..writeln('━━━━━━━━━━━━━━')
      ..write('_Poursuivez la réflexion ensemble sur Boroom Yitté._');
    return buf.toString();
  }

  /// Met en forme une publication / réflexion avec ses questions principales
  /// et commentaires des membres pour un partage WhatsApp élégant.
  static String formatReflectionForWhatsApp({
    required String title,
    required String authorName,
    required String body,
    List<String> mainQuestions = const [],
    List<({String author, String body})> comments = const [],
  }) {
    final buf = StringBuffer()
      ..writeln('*BOROOM YITTÉ YU KAWÉ YI*')
      ..writeln('_Réflexion partagée par ${authorName.trim()}_')
      ..writeln('━━━━━━━━━━━━━━')
      ..writeln('*${title.trim()}*')
      ..writeln()
      ..writeln(body.trim());

    if (mainQuestions.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('*Questions clés :*');
      for (int i = 0; i < mainQuestions.length; i++) {
        buf.writeln('${i + 1}. ${mainQuestions[i].trim()}');
      }
    }

    if (comments.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('*Questions & réactions des membres (${comments.length}) :*');
      for (final c in comments.take(6)) {
        buf
          ..writeln('*${c.author.trim()} :*')
          ..writeln('> ${c.body.trim().replaceAll('\n', '\n> ')}');
      }
    }

    buf
      ..writeln('━━━━━━━━━━━━━━')
      ..write('_Qu’en pensez-vous ? Répondez dans le cercle Boroom Yitté._');
    return buf.toString();
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
