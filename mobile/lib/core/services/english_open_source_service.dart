import 'dart:convert';

import 'package:http/http.dart' as http;

class DictionaryMeaning {
  final String partOfSpeech;
  final List<String> definitions;
  final List<String> examples;
  final List<String> synonyms;

  const DictionaryMeaning({
    required this.partOfSpeech,
    required this.definitions,
    required this.examples,
    required this.synonyms,
  });
}

class OpenDictionaryEntry {
  final String word;
  final String phonetic;
  final String? ukAudioUrl;
  final String? usAudioUrl;
  final List<DictionaryMeaning> meanings;
  final String? sourceUrl;

  const OpenDictionaryEntry({
    required this.word,
    required this.phonetic,
    this.ukAudioUrl,
    this.usAudioUrl,
    required this.meanings,
    this.sourceUrl,
  });

  String? preferredAudioFor(String variant) => variant == 'en-GB'
      ? (ukAudioUrl ?? usAudioUrl)
      : (usAudioUrl ?? ukAudioUrl);
}

class LanguageToolIssue {
  final String message;
  final String badText;
  final int offset;
  final int length;
  final List<String> replacements;
  final String category;

  const LanguageToolIssue({
    required this.message,
    required this.badText,
    required this.offset,
    required this.length,
    required this.replacements,
    required this.category,
  });
}

class LanguageToolCheckResult {
  final String originalText;
  final String correctedText;
  final List<LanguageToolIssue> issues;
  final bool usedOnlineApi;

  const LanguageToolCheckResult({
    required this.originalText,
    required this.correctedText,
    required this.issues,
    required this.usedOnlineApi,
  });
}

class CourseComparisonRow {
  final String avoid;
  final String natural;
  final String explanationFr;

  const CourseComparisonRow({
    required this.avoid,
    required this.natural,
    required this.explanationFr,
  });
}

class CourseDialogueLine {
  final String speaker;
  final String english;
  final String french;

  const CourseDialogueLine({
    required this.speaker,
    required this.english,
    required this.french,
  });
}

class CourseQuizItem {
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;

  const CourseQuizItem({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });
}

class ConcreteEnglishCourse {
  final String level;
  final String title;
  final String summaryFr;
  final List<String> coreRules;
  final List<CourseComparisonRow> comparisons;
  final List<CourseDialogueLine> dialogue;
  final List<CourseQuizItem> exercises;

  const ConcreteEnglishCourse({
    required this.level,
    required this.title,
    required this.summaryFr,
    required this.coreRules,
    required this.comparisons,
    required this.dialogue,
    required this.exercises,
  });
}

class CefrStageModule {
  final String level;
  final String title;
  final String objective;
  final List<String> orderedSteps;
  final String focusGrammar;
  final String oralTask;

  const CefrStageModule({
    required this.level,
    required this.title,
    required this.objective,
    required this.orderedSteps,
    required this.focusGrammar,
    required this.oralTask,
  });
}

class IrregularVerbEntry {
  final String base;
  final String past;
  final String participle;
  final String french;

  const IrregularVerbEntry({
    required this.base,
    required this.past,
    required this.participle,
    required this.french,
  });
}

class OpenLearningPortal {
  final String name;
  final String licenseOrAccess;
  final String summary;
  final String url;

  const OpenLearningPortal({
    required this.name,
    required this.licenseOrAccess,
    required this.summary,
    required this.url,
  });
}

/// Integrates two real open-source HTTPS APIs (Free Dictionary API MIT + LanguageTool LGPL)
/// alongside full concrete interactive courses A1 -> C2, Francophone error correction,
/// playable dialogues, irregular verbs, and verified free/open-source learning portals.
class EnglishOpenSourceService {
  EnglishOpenSourceService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, OpenDictionaryEntry> _cache = {};

  static OpenDictionaryEntry? parseDictionaryResponse(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List || decoded.isEmpty) return null;
    final first = Map<String, dynamic>.from(decoded.first as Map);
    final word = first['word']?.toString() ?? '';
    if (word.isEmpty) return null;

    var phonetic = first['phonetic']?.toString() ?? '';
    String? ukAudio;
    String? usAudio;

    final phonetics = first['phonetics'];
    if (phonetics is List) {
      for (final rawP in phonetics) {
        if (rawP is! Map) continue;
        final pText = rawP['text']?.toString() ?? '';
        if (phonetic.isEmpty && pText.isNotEmpty) phonetic = pText;
        var audio = rawP['audio']?.toString().trim() ?? '';
        if (audio.startsWith('//')) {
          audio = 'https:$audio';
        }
        if (audio.isEmpty) continue;
        final lower = audio.toLowerCase();
        if (lower.contains('-uk') ||
            lower.contains('_uk') ||
            lower.contains('uk.mp3') ||
            lower.contains('-gb') ||
            lower.contains('_gb') ||
            lower.contains('gb.mp3')) {
          ukAudio ??= audio;
        } else if (lower.contains('-us') ||
            lower.contains('_us') ||
            lower.contains('us.mp3')) {
          usAudio ??= audio;
        } else {
          ukAudio ??= audio;
          usAudio ??= audio;
        }
      }
    }

    final meanings = <DictionaryMeaning>[];
    final rawMeanings = first['meanings'];
    if (rawMeanings is List) {
      for (final rawM in rawMeanings) {
        if (rawM is! Map) continue;
        final pos = rawM['partOfSpeech']?.toString() ?? 'term';
        final defs = <String>[];
        final examples = <String>[];
        final synonyms = <String>[];

        if (rawM['synonyms'] is List) {
          for (final s in (rawM['synonyms'] as List).take(6)) {
            synonyms.add(s.toString());
          }
        }
        if (rawM['definitions'] is List) {
          for (final d in (rawM['definitions'] as List).take(4)) {
            if (d is! Map) continue;
            final defText = d['definition']?.toString().trim() ?? '';
            if (defText.isNotEmpty) defs.add(defText);
            final exText = d['example']?.toString().trim() ?? '';
            if (exText.isNotEmpty) examples.add(exText);
            if (synonyms.length < 6 && d['synonyms'] is List) {
              for (final s in (d['synonyms'] as List).take(3)) {
                synonyms.add(s.toString());
              }
            }
          }
        }
        if (defs.isNotEmpty) {
          meanings.add(
            DictionaryMeaning(
              partOfSpeech: pos,
              definitions: defs,
              examples: examples,
              synonyms: synonyms.toSet().toList(),
            ),
          );
        }
      }
    }

    String? sourceUrl;
    if (first['sourceUrls'] is List && (first['sourceUrls'] as List).isNotEmpty) {
      sourceUrl = (first['sourceUrls'] as List).first?.toString();
    }

    return OpenDictionaryEntry(
      word: word,
      phonetic: phonetic.isEmpty ? '/.../' : phonetic,
      ukAudioUrl: ukAudio,
      usAudioUrl: usAudio,
      meanings: meanings,
      sourceUrl: sourceUrl,
    );
  }

  Future<OpenDictionaryEntry?> lookupWord(String rawWord) async {
    final clean = rawWord.trim().toLowerCase();
    if (clean.isEmpty) return null;
    final cached = _cache[clean];
    if (cached != null) return cached;

    final uri = Uri.https(
      'api.dictionaryapi.dev',
      '/api/v2/entries/en/$clean',
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final parsed = parseDictionaryResponse(res.body);
    if (parsed != null) {
      _cache[clean] = parsed;
    }
    return parsed;
  }

  /// Parses LanguageTool Open-Source API JSON and builds the auto-corrected sentence.
  static LanguageToolCheckResult parseLanguageToolResponse(
    String originalText,
    String rawJson, {
    bool usedOnlineApi = true,
  }) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      return LanguageToolCheckResult(
        originalText: originalText,
        correctedText: originalText,
        issues: const [],
        usedOnlineApi: usedOnlineApi,
      );
    }
    final rawMatches = decoded['matches'] as List? ?? const [];
    final issues = <LanguageToolIssue>[];

    for (final m in rawMatches) {
      if (m is! Map) continue;
      final offset = (m['offset'] as num?)?.toInt() ?? 0;
      final length = (m['length'] as num?)?.toInt() ?? 0;
      if (offset < 0 || offset > originalText.length) continue;
      final end = (offset + length).clamp(offset, originalText.length);
      final bad = originalText.substring(offset, end);
      final reps = <String>[];
      if (m['replacements'] is List) {
        for (final r in (m['replacements'] as List).take(3)) {
          if (r is Map && r['value'] != null) {
            reps.add(r['value'].toString());
          }
        }
      }
      final cat = (m['rule'] is Map && (m['rule'] as Map)['category'] is Map)
          ? ((m['rule'] as Map)['category'] as Map)['name']?.toString() ?? 'Grammar'
          : 'Grammar';
      issues.add(
        LanguageToolIssue(
          message: m['message']?.toString() ?? 'Check this expression.',
          badText: bad,
          offset: offset,
          length: end - offset,
          replacements: reps,
          category: cat,
        ),
      );
    }

    // Apply non-overlapping replacements from end to start
    final sorted = List<LanguageToolIssue>.from(issues)
      ..sort((a, b) => b.offset.compareTo(a.offset));
    var corrected = originalText;
    var lastStart = corrected.length + 1;
    for (final issue in sorted) {
      if (issue.replacements.isEmpty) continue;
      final end = issue.offset + issue.length;
      if (end > lastStart) continue;
      corrected = corrected.replaceRange(
        issue.offset,
        end,
        issue.replacements.first,
      );
      lastStart = issue.offset;
    }

    return LanguageToolCheckResult(
      originalText: originalText,
      correctedText: corrected,
      issues: issues,
      usedOnlineApi: usedOnlineApi,
    );
  }

  /// Live open-source grammar check using LanguageTool public API (LGPL, CORS *, zero API key)
  /// with immediate local Francophone-English fallback when offline.
  Future<LanguageToolCheckResult> checkGrammarLive(
    String text, {
    String language = 'en-GB',
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      return const LanguageToolCheckResult(
        originalText: '',
        correctedText: '',
        issues: [],
        usedOnlineApi: false,
      );
    }
    try {
      final res = await _client
          .post(
            Uri.https('api.languagetool.org', '/v2/check'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'text': clean,
              'language': language == 'en-US' ? 'en-US' : 'en-GB',
            },
          )
          .timeout(const Duration(seconds: 7));
      if (res.statusCode == 200) {
        return parseLanguageToolResponse(clean, res.body, usedOnlineApi: true);
      }
    } catch (_) {
      // Smooth offline fallback below
    }
    return checkGrammarOffline(clean);
  }

  /// Local 15+ rule grammar corrector tailored for French speakers learning English.
  static LanguageToolCheckResult checkGrammarOffline(String text) {
    final rules = <({RegExp pattern, String replace, String msg, String cat})>[
      (
        pattern: RegExp(r'\bdespite of\b', caseSensitive: false),
        replace: 'despite',
        msg: 'On dit "despite + nom" ou "in spite of", jamais "despite of".',
        cat: 'Preposition',
      ),
      (
        pattern: RegExp(r'\bdiscuss about\b', caseSensitive: false),
        replace: 'discuss',
        msg: '"Discuss" est transitif direct : "discuss the project" (sans "about").',
        cat: 'Preposition',
      ),
      (
        pattern: RegExp(r'\bdepend of\b', caseSensitive: false),
        replace: 'depend on',
        msg: 'En anglais on utilise toujours "depend on", jamais "depend of".',
        cat: 'Preposition',
      ),
      (
        pattern: RegExp(r'\binformations\b', caseSensitive: false),
        replace: 'information',
        msg: '"Information" est indénombrable en anglais (pas de -s).',
        cat: 'Uncountable Noun',
      ),
      (
        pattern: RegExp(r'\badvices\b', caseSensitive: false),
        replace: 'advice',
        msg: '"Advice" est indénombrable : dites "some advice" ou "a piece of advice".',
        cat: 'Uncountable Noun',
      ),
      (
        pattern: RegExp(r'\bequipments\b', caseSensitive: false),
        replace: 'equipment',
        msg: '"Equipment" est indénombrable en anglais (pas de pluriel en -s).',
        cat: 'Uncountable Noun',
      ),
      (
        pattern: RegExp(r'\bI am agree\b', caseSensitive: false),
        replace: 'I agree',
        msg: '"Agree" est un verbe : dites "I agree" (jamais "I am agree").',
        cat: 'Verb Usage',
      ),
      (
        pattern: RegExp(r'\bexplain me\b', caseSensitive: false),
        replace: 'explain to me',
        msg: 'On dit toujours "explain [something] to me" (avec "to").',
        cat: 'Preposition',
      ),
      (
        pattern: RegExp(r'\bI have (\d+) years\b', caseSensitive: false),
        replace: r'I am $1 years old',
        msg: 'Pour l’âge en anglais, on utilise "to be" : "I am ... years old".',
        cat: 'Francophone Trap',
      ),
      (
        pattern: RegExp(r'\bmake (my |the )?homework\b', caseSensitive: false),
        replace: 'do homework',
        msg: 'Avec "homework / research / work", on utilise "do" (pas "make").',
        cat: 'Make vs Do',
      ),
      (
        pattern: RegExp(r'\bmore better\b', caseSensitive: false),
        replace: 'much better',
        msg: '"Better" est déjà un comparatif : dites "much better", jamais "more better".',
        cat: 'Comparative',
      ),
      (
        pattern: RegExp(r'\bI did not went\b', caseSensitive: false),
        replace: 'I did not go',
        msg: 'Après l’auxiliaire "did/didn’t", le verbe revient toujours à la base ("go").',
        cat: 'Past Simple',
      ),
      (
        pattern: RegExp(r"\bhe don't\b", caseSensitive: false),
        replace: "he doesn't",
        msg: 'À la 3e personne du singulier (he/she/it), utilisez "doesn’t".',
        cat: 'Agreement',
      ),
      (
        pattern: RegExp(r"\bshe don't\b", caseSensitive: false),
        replace: "she doesn't",
        msg: 'À la 3e personne du singulier (he/she/it), utilisez "doesn’t".',
        cat: 'Agreement',
      ),
      (
        pattern: RegExp(r'\ba ([aeiouAEIOU]\w+)'),
        replace: r'an $1',
        msg: 'Utilisez "an" devant un son voyelle (ex. "an important project").',
        cat: 'Article',
      ),
      (
        pattern: RegExp(r'(^|\s)i(\s)'),
        replace: r'$1I$2',
        msg: 'Le pronom "I" (je) prend toujours une majuscule en anglais.',
        cat: 'Capitalization',
      ),
    ];

    var corrected = text;
    final issues = <LanguageToolIssue>[];
    for (final rule in rules) {
      final m = rule.pattern.firstMatch(corrected);
      if (m != null) {
        final bad = m.group(0) ?? '';
        final rep = bad.replaceFirstMapped(rule.pattern, (match) {
          if (rule.replace.contains(r'$1')) {
            return rule.replace
                .replaceAll(r'$1', match.group(1) ?? '')
                .replaceAll(r'$2', match.groupCount >= 2 ? (match.group(2) ?? '') : '');
          }
          return rule.replace;
        });
        issues.add(
          LanguageToolIssue(
            message: rule.msg,
            badText: bad.trim(),
            offset: m.start,
            length: m.end - m.start,
            replacements: [rep.trim()],
            category: rule.cat,
          ),
        );
        corrected = corrected.replaceRange(m.start, m.end, rep);
      }
    }

    return LanguageToolCheckResult(
      originalText: text,
      correctedText: corrected,
      issues: issues,
      usedOnlineApi: false,
    );
  }

  /// Concrete, genuinely helpful bilingual English Coach combining:
  /// 1) Specific structured answers for French/English learning questions, AND
  /// 2) Live LanguageTool Open-Source grammar/style correction for English sentences.
  Future<String> askEnglishCoachLive({
    required String input,
    required String variant,
    required String cefrLevel,
  }) async {
    final clean = input.trim();
    if (clean.isEmpty) {
      return 'Écrivez une phrase en anglais à corriger ou posez une question précise (ex. "For vs Since", "Present Perfect", "Faux amis", "Entretien STAR").';
    }
    final q = clean.toLowerCase();

    // 1. Concrete bilingual lessons for direct grammar / method questions
    if (q.contains('for') && q.contains('since')) {
      return '📘 FOR vs SINCE (Règle concrète — Niveau $cefrLevel)\n'
          '• FOR + une DURÉE (pendant combien de temps) :\n'
          '  ✅ I have lived in Dakar FOR 5 years. / She studied FOR two hours.\n'
          '• SINCE + un POINT DE DÉPART précis (depuis quand) :\n'
          '  ✅ I have worked here SINCE 2023. / We have waited SINCE Monday.\n'
          '❌ Piège francophone : ne dites jamais "I live here since 3 years" → ✅ "I have lived here for 3 years."\n'
          '🎯 Exercice : Complétez → "He has practised English ____ January." (Réponse : since)';
    }
    if (q.contains('present perfect') || (q.contains('pass') && q.contains('perfect'))) {
      return '📘 PRESENT PERFECT vs PAST SIMPLE (Règle concrète)\n'
          '• PAST SIMPLE (verbe + -ed / 2e colonne) : action TERMINÉE et DATÉE dans le passé.\n'
          '  ✅ Yesterday, I finished the report. / In 2026, we launched BOROOM YITTÉ.\n'
          '• PRESENT PERFECT (have/has + participe passé) : lien direct avec le PRÉSENT ou expérience sans date précise.\n'
          '  ✅ I have already finished the report (il est prêt maintenant).\n'
          '  ✅ Have you ever worked on an international project?\n'
          '❌ Erreur fréquente : "I have seen him yesterday" → ✅ "I saw him yesterday."';
    }
    if (q.contains('make') && q.contains('do')) {
      return '📘 MAKE vs DO (Tableau indispensable)\n'
          '• DO = tâches, travail, devoirs, recherches, actions générales :\n'
          '  ✅ do homework • do research • do business • do your best • do an exercise\n'
          '• MAKE = créer, produire, décider, provoquer un résultat :\n'
          '  ✅ make a decision • make progress • make a mistake • make an effort • make a plan\n'
          '❌ "I must make my homework" → ✅ "I must do my homework."';
    }
    if (q.contains('faux ami') || q.contains('false friend')) {
      return '📘 7 FAUX AMIS FR → EN À CONNAÎTRE ABSOLUMENT\n'
          '1. Actually = en fait / réellement (et PAS "actuellement" → currently)\n'
          '2. Eventually = finalement / à terme (et PAS "éventuellement" → possibly)\n'
          '3. Sensible = raisonnable / censé (et PAS "sensible" → sensitive)\n'
          '4. Attend = assister à / participer (et PAS "attendre" → wait for)\n'
          '5. Library = bibliothèque (et PAS "librairie" → bookshop)\n'
          '6. Resume (n.) = CV ; resume (v.) = reprendre (et PAS "résumer" → summarize)\n'
          '7. Delay = retard (et PAS "délai / date limite" → deadline)';
    }
    if (q.contains('in') && q.contains('on') && q.contains('at') ||
        q.contains('préposition') ||
        q.contains('preposition')) {
      return '📘 PRÉPOSITIONS IN / ON / AT (Pyramide simple)\n'
          '• IN (large : mois, années, saisons, villes, pays) : in 2026, in November, in Dakar, in the morning.\n'
          '• ON (précis : jours, dates, surfaces) : on Monday, on July 4th, on the table, on the website.\n'
          '• AT (très précis : heures exactes, lieux ponctuels) : at 8:00 PM, at night, at home, at the university.';
    }
    if (q.contains('conditionnel') || q.contains('conditional') || q.contains('would have')) {
      return '📘 LES 3 CONDITIONNELS EN ANGLAIS\n'
          '• 1er (Réel/probable) : If + Present Simple, WILL + base\n'
          '  → If you practice 20 minutes daily, you will improve quickly.\n'
          '• 2e (Imaginaire/présent) : If + Past Simple, WOULD + base\n'
          '  → If I had more time, I would build an open-source course.\n'
          '• 3e (Regret/passé) : If + had + V3, WOULD HAVE + V3\n'
          '  → If we had tested earlier, we would have avoided that bug.';
    }
    if (q.contains('entretien') || q.contains('interview') || q.contains('star')) {
      return '📘 RÉUSSIR UN ENTRETIEN EN ANGLAIS (Méthode STAR)\n'
          '• S (Situation) : "In my previous project at..., we faced a major bottleneck..."\n'
          '• T (Task) : "My responsibility was to design and validate a reliable solution within two weeks."\n'
          '• A (Action) : "I analysed the root cause, collaborated with the team, and implemented..."\n'
          '• R (Result) : "As a result, we reduced errors by 35% and delivered ahead of schedule."\n'
          '💡 Astuce : Collez votre propre réponse en anglais ici et je la corrige ligne par ligne avec LanguageTool !';
    }
    if (q.contains('although') || q.contains('despite')) {
      return '📘 ALTHOUGH vs DESPITE\n'
          '• ALTHOUGH / EVEN THOUGH + Sujet + Verbe :\n'
          '  ✅ Although it was difficult, she delivered an excellent presentation.\n'
          '• DESPITE / IN SPITE OF + Nom ou Verbe-ing (JAMAIS "despite of" !) :\n'
          '  ✅ Despite the difficulty, she delivered an excellent presentation.\n'
          '  ✅ Despite feeling tired, he completed his daily study session.';
    }
    if (q.contains('phrasal')) {
      return '📘 8 PHRASAL VERBS ESSENTIELS (Vie pro & quotidienne)\n'
          '• carry out = mener à bien (carry out an experiment)\n'
          '• figure out = comprendre / trouver une solution\n'
          '• bring up = soulever un sujet en réunion\n'
          '• follow up = faire le suivi\n'
          '• look into = examiner en détail / enquêter\n'
          '• put off = reporter à plus tard\n'
          '• break down = décomposer un problème (ou tomber en panne)\n'
          '• come up with = proposer une idée / solution';
    }
    if (q.contains('prononciation') || q.contains('pronunciation')) {
      return '📘 3 RÈGLES D’OR DE PRONONCIATION ($variant)\n'
          '1. Le "TH" : placez légèrement la pointe de la langue entre les dents (think /θ/, this /ð/) — ne remplacez pas par "s/z".\n'
          '2. La fin "-ED" au passé :\n'
          '   • /ɪd/ après t/d (wanted, needed)\n'
          '   • /t/ après son sourd p/k/f/s/sh/ch (worked, watched)\n'
          '   • /d/ dans tous les autres cas (played, lived)\n'
          '3. Le "H" initial est toujours expiré (happy, house, hospital).';
    }

    // 2. Otherwise treat as English text to check live with LanguageTool Open-Source API!
    final result = await checkGrammarLive(clean, language: variant);
    final engineLabel = result.usedOnlineApi
        ? 'LanguageTool Open-Source (en direct, $variant)'
        : 'Correcteur hors-ligne FR→EN ($variant)';
    final buf = StringBuffer()
      ..writeln('🔎 Analyse Coach ($engineLabel) :');

    if (result.issues.isEmpty) {
      buf
        ..writeln('✅ Aucune erreur grammaticale majeure détectée dans votre phrase !')
        ..writeln('• Phrase validée : "${result.correctedText}"')
        ..writeln(
          '💡 Pour aller plus loin ($cefrLevel) : essayez d’ajouter un connecteur logique ("furthermore", "however", "consequently") ou un exemple concret.',
        );
    } else {
      buf
        ..writeln('✅ Version corrigée : "${result.correctedText}"')
        ..writeln('')
        ..writeln('📌 ${result.issues.length} point(s) corrigé(s) :');
      for (final issue in result.issues.take(5)) {
        final repText = issue.replacements.isNotEmpty
            ? ' → ${issue.replacements.join(" / ")}'
            : '';
        buf.writeln('• [${issue.category}] "${issue.badText}"$repText : ${issue.message}');
      }
    }
    return buf.toString().trim();
  }

  static const List<ConcreteEnglishCourse> concreteCourses = [
    ConcreteEnglishCourse(
      level: 'A1',
      title: 'Cours A1 — Se présenter, To Be / To Have & Présent Simple',
      summaryFr:
          'Construire des phrases correctes dès le premier jour et éviter les calques du français.',
      coreRules: [
        'To BE (être) s’utilise aussi pour l’âge, la faim, la soif et le froid : "I am 23 years old", "I am hungry".',
        'Présent simple : on ajoute -s / -es à la 3e personne (he/she/it works, studies, goes).',
        'Questions & négations : on utilise toujours DO / DOES + base verbale ("Do you speak English?", "He doesn’t work on Sunday").',
      ],
      comparisons: [
        CourseComparisonRow(
          avoid: 'I have 25 years. ❌',
          natural: 'I am 25 years old. ✅',
          explanationFr: 'L’âge utilise toujours le verbe "to be" en anglais.',
        ),
        CourseComparisonRow(
          avoid: 'She work in Dakar. ❌',
          natural: 'She works in Dakar. ✅',
          explanationFr: 'Ne jamais oublier le -s à he/she/it au présent simple.',
        ),
        CourseComparisonRow(
          avoid: 'I am agree with you. ❌',
          natural: 'I agree with you. ✅',
          explanationFr: '"Agree" est un verbe direct (pas un adjectif).',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amina',
          english: 'Hello! My name is Amina. What do you study or do for a living?',
          french: 'Bonjour ! Je m’appelle Amina. Qu’est-ce que tu étudies ou fais dans la vie ?',
        ),
        CourseDialogueLine(
          speaker: 'Moussa',
          english: 'Nice to meet you, Amina. I am an agronomy student and I live in Dakar.',
          french: 'Ravi de te rencontrer Amina. Je suis étudiant en agronomie et j’habite à Dakar.',
        ),
        CourseDialogueLine(
          speaker: 'Amina',
          english: 'That sounds great! Do you practice English every day?',
          french: 'C’est super ! Est-ce que tu pratiques l’anglais tous les jours ?',
        ),
        CourseDialogueLine(
          speaker: 'Moussa',
          english: 'Yes, I listen to short lessons for twenty minutes every morning.',
          french: 'Oui, j’écoute de courtes leçons pendant vingt minutes chaque matin.',
        ),
      ],
      exercises: [
        CourseQuizItem(
          question: 'Choisissez la phrase correcte : "J’ai 24 ans."',
          options: ['I have 24 years.', 'I am 24 years old.', 'I am having 24.'],
          answer: 'I am 24 years old.',
          explanation: 'En anglais, l’âge se construit avec "to be" + years old.',
        ),
        CourseQuizItem(
          question: 'Complétez : "_____ your brother live near the university?"',
          options: ['Do', 'Does', 'Is'],
          answer: 'Does',
          explanation: '"Your brother" = he (3e personne singulier) → auxiliaire "Does".',
        ),
      ],
    ),
    ConcreteEnglishCourse(
      level: 'A2',
      title: 'Cours A2 — Raconter au Passé, Prépositions (In/On/At) & Make vs Do',
      summaryFr:
          'Maîtriser le prétérit (Past Simple), situer dans le temps/l’espace et choisir entre Make et Do.',
      coreRules: [
        'Past Simple affirmatif : verbe régulier + -ed (worked, studied) ou 2e colonne irrégulière (went, built, spoke).',
        'Past Simple négatif/question : DID / DIDN’T + BASE verbale ("Did you go?", "I didn’t see" — JAMAIS "didn’t went").',
        'IN (mois, année, ville) • ON (jour, date) • AT (heure exacte, lieu précis).',
      ],
      comparisons: [
        CourseComparisonRow(
          avoid: 'I didn’t went to class. ❌',
          natural: 'I didn’t go to class. ✅',
          explanationFr: 'Après "did/didn’t", le verbe reste toujours à la forme de base.',
        ),
        CourseComparisonRow(
          avoid: 'I must make my homework. ❌',
          natural: 'I must do my homework. ✅',
          explanationFr: 'Tâches/devoirs/recherches → DO ; décisions/créations → MAKE.',
        ),
        CourseComparisonRow(
          avoid: 'The meeting is in Monday at the morning. ❌',
          natural: 'The meeting is on Monday in the morning. ✅',
          explanationFr: 'On + jour (on Monday), in + moment de la journée (in the morning).',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Fatou',
          english: 'What did you do last weekend?',
          french: 'Qu’as-tu fait le week-end dernier ?',
        ),
        CourseDialogueLine(
          speaker: 'Khadim',
          english: 'On Saturday morning, I did some research for our electronics project.',
          french: 'Samedi matin, j’ai fait des recherches pour notre projet d’électronique.',
        ),
        CourseDialogueLine(
          speaker: 'Fatou',
          english: 'Did you make good progress?',
          french: 'As-tu bien avancé ?',
        ),
        CourseDialogueLine(
          speaker: 'Khadim',
          english: 'Yes! We solved the circuit bug and wrote the full summary at 6 PM.',
          french: 'Oui ! Nous avons résolu le bug du circuit et rédigé tout le résumé à 18h.',
        ),
      ],
      exercises: [
        CourseQuizItem(
          question: 'Complétez : "Yesterday, she _____ a very clear presentation."',
          options: ['give', 'gave', 'has given'],
          answer: 'gave',
          explanation: '"Yesterday" indique un passé terminé et daté → Past Simple ("gave").',
        ),
        CourseQuizItem(
          question: 'Complétez : "We need to _____ a clear decision before Friday."',
          options: ['do', 'make', 'take'],
          answer: 'make',
          explanation: 'En anglais naturel, on dit toujours "make a decision".',
        ),
      ],
    ),
    ConcreteEnglishCourse(
      level: 'B1',
      title: 'Cours B1 — Present Perfect vs Past, For/Since & Faux Amis FR→EN',
      summaryFr:
          'Faire la différence entre action passée close et bilan présent, et éliminer les faux amis.',
      coreRules: [
        'Present Perfect (have/has + V3) relie le passé au présent : "I have worked here for 3 years" (j’y travaille encore).',
        'FOR + durée ("for two weeks") vs SINCE + point de départ ("since 2026", "since Monday").',
        'Faux amis clés : actually = en fait, currently = actuellement, eventually = finalement, attend = assister à.',
      ],
      comparisons: [
        CourseComparisonRow(
          avoid: 'I study English since 2 years. ❌',
          natural: 'I have studied English for 2 years. ✅',
          explanationFr: 'Durée commencée dans le passé qui continue → Present Perfect + FOR.',
        ),
        CourseComparisonRow(
          avoid: 'Actually, I work in Saint-Louis. ❌',
          natural: 'Currently, I work in Saint-Louis. ✅',
          explanationFr: '"Actually" veut dire "en fait" ; "actuellement" se traduit par "currently".',
        ),
        CourseComparisonRow(
          avoid: 'Despite of the rain, we attended. ❌',
          natural: 'Despite the rain, we attended. ✅',
          explanationFr: '"Despite" ne prend jamais "of" ; "in spite of" le prend.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Diarra',
          english: 'How long have you been part of the community?',
          french: 'Depuis combien de temps fais-tu partie de la communauté ?',
        ),
        CourseDialogueLine(
          speaker: 'Bamba',
          english:
              'I have been a member of BOROOM YITTÉ since 2026, and we have worked together for several months.',
          french:
              'Je suis membre de BOROOM YITTÉ depuis 2026, et nous travaillons ensemble depuis plusieurs mois.',
        ),
        CourseDialogueLine(
          speaker: 'Diarra',
          english: 'Actually, I noticed your English fluency has improved a lot!',
          french: 'En fait, j’ai remarqué que ton aisance en anglais s’est beaucoup améliorée !',
        ),
        CourseDialogueLine(
          speaker: 'Bamba',
          english: 'Thank you! Speaking regularly despite small mistakes really helped me.',
          french: 'Merci ! Parler régulièrement malgré les petites erreurs m’a vraiment aidé.',
        ),
      ],
      exercises: [
        CourseQuizItem(
          question: 'Complétez : "She has worked as a doctor _____ 2021."',
          options: ['for', 'since', 'during'],
          answer: 'since',
          explanation: '"2021" est un point de départ précis → "since".',
        ),
        CourseQuizItem(
          question: 'Comment traduire « Actuellement, je prépare mon mémoire » ?',
          options: [
            'Actually, I prepare my thesis.',
            'Currently, I am working on my thesis.',
            'Eventually, I work on my thesis.',
          ],
          answer: 'Currently, I am working on my thesis.',
          explanation: '"Currently" = actuellement + Present Continuous pour une action en cours.',
        ),
      ],
    ),
    ConcreteEnglishCourse(
      level: 'B2',
      title: 'Cours B2 — Conditionnels (1–2–3), Voix Passive & Phrasal Verbs',
      summaryFr:
          'Exprimer des hypothèses précises, rédiger dans un registre technique et utiliser les phrasal verbs.',
      coreRules: [
        '2e conditionnel (hypothèse présente) : If + Past Simple, would + base.',
        '3e conditionnel (hypothèse passée) : If + had + V3, would have + V3.',
        'Voix passive technique : be (conjugué) + V3 ("The sensor was calibrated before deployment").',
      ],
      comparisons: [
        CourseComparisonRow(
          avoid: 'If I would have time, I would come. ❌',
          natural: 'If I had time, I would come. ✅',
          explanationFr: 'Pas de "would" dans la proposition en "If" en anglais standard.',
        ),
        CourseComparisonRow(
          avoid: 'We discussed about the new protocol. ❌',
          natural: 'We discussed the new protocol. ✅',
          explanationFr: '"Discuss" est suivi directement du complément d’objet.',
        ),
        CourseComparisonRow(
          avoid: 'Can you explain me this formula? ❌',
          natural: 'Can you explain this formula to me? ✅',
          explanationFr: 'Structure obligatoire : explain + something + to someone.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Engineer',
          english: 'Had we checked the battery voltage earlier, we would have avoided the outage.',
          french: 'Si nous avions vérifié la tension de batterie plus tôt, nous aurions évité la coupure.',
        ),
        CourseDialogueLine(
          speaker: 'Lead',
          english: 'Good point. Let us look into the root cause and come up with a checklist.',
          french: 'Bien vu. Examinons la cause racine et élaborons une liste de contrôle.',
        ),
        CourseDialogueLine(
          speaker: 'Engineer',
          english: 'I will carry out the load test today and follow up with the full metrics tonight.',
          french: 'Je vais effectuer le test de charge aujourd’hui et envoyer les mesures ce soir.',
        ),
      ],
      exercises: [
        CourseQuizItem(
          question: 'Complétez : "If we had verified the data, we _____ caught the mistake."',
          options: ['will have', 'would have', 'would'],
          answer: 'would have',
          explanation: '3e conditionnel : If + had + V3 → would have + V3.',
        ),
        CourseQuizItem(
          question: 'Quel phrasal verb signifie « examiner en détail / enquêter » ?',
          options: ['put off', 'look into', 'give up'],
          answer: 'look into',
          explanation: '"Look into an issue" = examiner un problème en profondeur.',
        ),
      ],
    ),
    ConcreteEnglishCourse(
      level: 'C1',
      title: 'Cours C1 — Leadership, Entretien STAR & Inversions Stylistiques',
      summaryFr:
          'Convaincre en entretien international, synthétiser des rapports et maîtriser les inversions formelles.',
      coreRules: [
        'Inversion après adverbe négatif/restrictif en tête : "Not only DID we reduce costs, but we also improved reliability."',
        'Conditionnel 3 inversé sans "if" : "Had we delayed the rollout, the impact would have been severe."',
        'Noms indénombrables en milieu pro : information, advice, equipment, research, feedback, progress (JAMAIS au pluriel).',
      ],
      comparisons: [
        CourseComparisonRow(
          avoid: 'Thanks for your helpful feedbacks and advices. ❌',
          natural: 'Thank you for your helpful feedback and advice. ✅',
          explanationFr: '"Feedback" et "advice" sont toujours indénombrables en anglais.',
        ),
        CourseComparisonRow(
          avoid: 'Not only we improved speed, we cut cost. ❌',
          natural: 'Not only did we improve speed, but we also cut costs. ✅',
          explanationFr: 'Après "Not only" en début de phrase, on inverse l’auxiliaire ("did we").',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Recruiter',
          english: 'Tell me about a complex challenge where you had to align different specialists.',
          french: 'Parlez-moi d’un défi complexe où vous avez dû coordonner plusieurs spécialistes.',
        ),
        CourseDialogueLine(
          speaker: 'Candidate',
          english: 'In our rural water project, agronomists and software engineers initially used incompatible metrics.',
          french: 'Dans notre projet d’eau rurale, agronomes et développeurs utilisaient d’abord des indicateurs incompatibles.',
        ),
        CourseDialogueLine(
          speaker: 'Candidate',
          english: 'Not only did I facilitate a shared specification, but I also built an automated dashboard that cut water waste by 28%.',
          french: 'Non seulement j’ai animé un cahier des charges commun, mais j’ai aussi conçu un tableau de bord réduisant les pertes d’eau de 28 %.',
        ),
      ],
      exercises: [
        CourseQuizItem(
          question: 'Complétez : "Not only _____ the deadline, but she also documented every step."',
          options: ['she met', 'did she meet', 'she did meet'],
          answer: 'did she meet',
          explanation: 'Inversion obligatoire après "Not only" en tête de phrase : auxiliaire + sujet + base.',
        ),
      ],
    ),
    ConcreteEnglishCourse(
      level: 'C2',
      title: 'Cours C2 — Rhétorique, Nuance Académique & Hedging de Précision',
      summaryFr:
          'Nuancer une thèse scientifique ou philosophique sans absolutisme, en registre académique international.',
      coreRules: [
        'Hedging académique : remplacer les affirmations absolues par "evidence suggests that", "to a significant extent", "it appears plausible that".',
        'Concessions sophistiquées : "Notwithstanding these constraints...", "Albeit preliminary, the findings indicate...", "Granted that...".',
        'Cohérence UK vs US : choisir une convention orthographique constante (analyse/analyze, programme/program, colour/color).',
      ],
      comparisons: [
        CourseComparisonRow(
          avoid: 'This proves 100% that technology always ruins thinking. ❌',
          natural: 'While excessive reliance may erode analytical habits, structured use appears to enhance critical inquiry. ✅',
          explanationFr: 'Le registre C2 privilégie la nuance fondée sur des preuves plutôt que l’exagération.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Moderator',
          english: 'Notwithstanding the rapid pace of automation, where does irreplaceable human discernment remain decisive?',
          french: 'Malgré le rythme rapide de l’automatisation, où le discernement humain irremplaçable reste-t-il décisif ?',
        ),
        CourseDialogueLine(
          speaker: 'Panelist',
          english: 'Granted that algorithms excel at pattern synthesis, ethical accountability and contextual wisdom cannot be outsourced.',
          french: 'Bien que les algorithmes excellent dans la synthèse de motifs, la responsabilité éthique et la sagesse contextuelle ne se délèguent pas.',
        ),
      ],
      exercises: [
        CourseQuizItem(
          question: 'Quel connecteur formel signifie « bien que / quoique » devant un adjectif ?',
          options: ['Albeit', 'Whereas', 'Unless'],
          answer: 'Albeit',
          explanation: '"Albeit" s’emploie élégamment devant un adjectif ou groupe nominal ("albeit brief").',
        ),
      ],
    ),
  ];

  static ConcreteEnglishCourse courseForLevel(String level) =>
      concreteCourses.firstWhere(
        (c) => c.level == level,
        orElse: () => concreteCourses[2],
      );

  static const List<CefrStageModule> curriculum = [
    CefrStageModule(
      level: 'A1',
      title: 'Palier 1 — Fondations, Sons & Survie Active',
      objective: 'Maîtriser les sons IPA essentiels, se présenter et poser des questions simples.',
      orderedSteps: [
        '1. Phonétique : distinguer voyelles courtes/longues (/ɪ/ vs /iː/) et th (/θ/, /ð/).',
        '2. Grammaire : to be, to have, présent simple, articles a/an/the.',
        '3. Lexique : identité, horaires, études, famille et actions quotidiennes.',
        '4. Pratique orale : présentation audio de 45s réécoutée et corrigée.',
      ],
      focusGrammar: 'Présent simple + questions Wh- (What, Where, When, Why, How).',
      oralTask: 'Introduce yourself, your profession/field, and one daily habit in 45 seconds.',
    ),
    CefrStageModule(
      level: 'A2',
      title: 'Palier 2 — Récits du Passé & Projets Concrets',
      objective: 'Raconter des événements passés, comparer et planifier un projet simple.',
      orderedSteps: [
        '1. Phonétique : terminaisons -ed (/t/, /d/, /ɪd/) et formes faibles (to, for, of).',
        '2. Grammaire : Past Simple régulier/irrégulier, Comparatifs, Future (going to / will).',
        '3. Lexique : déplacements, travail d’équipe, santé et environnement.',
        '4. Pratique orale : raconter une réalisation passée de 60s avec 5 verbes irréguliers.',
      ],
      focusGrammar: 'Past Simple vs Past Continuous + prépositions (in, on, at, since, for).',
      oralTask: 'Describe a problem you solved recently and what happened step by step.',
    ),
    CefrStageModule(
      level: 'B1',
      title: 'Palier 3 — Autonomie & Argumentation Structurée',
      objective: 'Relier l’expérience présente au passé et défendre un point de vue nuancé.',
      orderedSteps: [
        '1. Intonation : accentuation des mots-clés et liaisons naturelles.',
        '2. Grammaire : Present Perfect, modaux (should, must, might), connecteurs (although vs despite).',
        '3. Lexique : éthique numérique, sciences appliquées et vie professionnelle.',
        '4. Pratique orale : mini-exposé de 90s (thèse -> exemple -> nuance) noté sur 100 pts.',
      ],
      focusGrammar: 'Although + clause vs Despite / In spite of + noun/gerund ; Present Perfect.',
      oralTask: 'Explain the benefits and risks of AI tools for university and community learning.',
    ),
    CefrStageModule(
      level: 'B2',
      title: 'Palier 4 — Précision Professionnelle & Conditionnels',
      objective: 'Analyser des hypothèses, animer un débat ou mener un entretien technique en anglais.',
      orderedSteps: [
        '1. Compréhension : écouter un document technique/scientifique sans sous-titres.',
        '2. Grammaire : Conditionnels 1-2-3, Voix passive, discours indirect et Phrasal Verbs.',
        '3. Lexique : gestion de projet, agronomie, médecine, ingénierie et logique.',
        '4. Pratique orale : répondre à une objection ou une question STAR en 2 minutes.',
      ],
      focusGrammar: 'Third Conditional ("Had we checked..., we would have avoided...") & Passive.',
      oralTask: 'Present a project failure or risk you mitigated using the STAR framework.',
    ),
    CefrStageModule(
      level: 'C1',
      title: 'Palier 5 — Leadership, Synthèse & Registre Académique',
      objective: 'Produire des discours fluides, nuancés et précis sans recherche laborieuse de mots.',
      orderedSteps: [
        '1. Prosodie : rythme argumentatif, pauses stratégiques et emphase.',
        '2. Grammaire : inversions négatives (Not only did..., Seldom have...), propositions participiales.',
        '3. Lexique : collocations formelles et vocabulaire académique abstrait.',
        '4. Pratique orale : soutenance de 3 minutes sans notes + réfutation respectueuse.',
      ],
      focusGrammar: 'Inversions stylistiques, subjunctive formel et hedging ("It appears that...").',
      oralTask: 'Deliver a 3-minute synthesis connecting scientific integrity and community ethics.',
    ),
    CefrStageModule(
      level: 'C2',
      title: 'Palier 6 — Maîtrise Rhétorique & Équivalence Multiculturelle',
      objective: 'Naviguer aisément entre registres britannique, américain et académique international.',
      orderedSteps: [
        '1. Nuances : distinction registre formel/familier et différences UK/US.',
        '2. Rhétorique : concession fine, ironie mesurée et reformulation instantanée.',
        '3. Lecture : textes philosophiques, brevets, revues médicales et techniques.',
        '4. Pratique orale : modération de débat contradictoire en direct.',
      ],
      focusGrammar: 'Ellipses élégantes, nuances idiomatiques et précision terminologique.',
      oralTask: 'Moderate a bilingual summary translating complex arguments without loss of nuance.',
    ),
  ];

  static const List<IrregularVerbEntry> irregularVerbs = [
    IrregularVerbEntry(base: 'begin', past: 'began', participle: 'begun', french: 'commencer'),
    IrregularVerbEntry(base: 'build', past: 'built', participle: 'built', french: 'construire'),
    IrregularVerbEntry(base: 'choose', past: 'chose', participle: 'chosen', french: 'choisir'),
    IrregularVerbEntry(base: 'know', past: 'knew', participle: 'known', french: 'savoir / connaître'),
    IrregularVerbEntry(base: 'lead', past: 'led', participle: 'led', french: 'diriger / mener'),
    IrregularVerbEntry(base: 'learn', past: 'learnt / learned', participle: 'learnt / learned', french: 'apprendre'),
    IrregularVerbEntry(base: 'read', past: 'read (/rɛd/)', participle: 'read (/rɛd/)', french: 'lire'),
    IrregularVerbEntry(base: 'speak', past: 'spoke', participle: 'spoken', french: 'parler'),
    IrregularVerbEntry(base: 'teach', past: 'taught', participle: 'taught', french: 'enseigner'),
    IrregularVerbEntry(base: 'think', past: 'thought', participle: 'thought', french: 'penser / réfléchir'),
    IrregularVerbEntry(base: 'understand', past: 'understood', participle: 'understood', french: 'comprendre'),
    IrregularVerbEntry(base: 'write', past: 'wrote', participle: 'written', french: 'écrire'),
  ];

  static const List<OpenLearningPortal> openPortals = [
    OpenLearningPortal(
      name: 'LanguageTool Open-Source Engine (LGPL)',
      licenseOrAccess: 'Open-Source LGPL — Intégré en direct dans notre Coach !',
      summary: 'Correcteur grammatical, syntaxique et stylistique anglais UK/US en temps réel.',
      url: 'https://languagetool.org/',
    ),
    OpenLearningPortal(
      name: 'Wikibooks — English in Use (Cours complet libre)',
      licenseOrAccess: 'Licence libre CC-BY-SA',
      summary: 'Manuel complet open-source de grammaire, syntaxe, orthographe et rédaction anglaise.',
      url: 'https://en.wikibooks.org/wiki/English_in_Use',
    ),
    OpenLearningPortal(
      name: 'British Council LearnEnglish (Cours gratuits A1 → C1)',
      licenseOrAccess: 'Accès gratuit officiel',
      summary: 'Leçons complètes par niveau : Grammar, Listening, Reading, Speaking, Business English.',
      url: 'https://learnenglish.britishcouncil.org/grammar',
    ),
    OpenLearningPortal(
      name: 'BBC Learning English — Cours structurés & 6 Minute English',
      licenseOrAccess: 'Accès gratuit éducatif',
      summary: 'Cours complets par unités (Lower/Upper Intermediate, Towards Advanced) + audio et scripts.',
      url: 'https://www.bbc.co.uk/learningenglish/english/course/lower-intermediate',
    ),
    OpenLearningPortal(
      name: 'VOA Learning English — Let’s Learn English (52 leçons)',
      licenseOrAccess: 'Domaine public (US Gov Open Educational Resource)',
      summary: 'Programme complet de 52 leçons vidéo/audio avec fiches d’exercices téléchargeables.',
      url: 'https://learningenglish.voanews.com/z/4729',
    ),
    OpenLearningPortal(
      name: 'Free Dictionary API (Open-Source MIT / Wiktionary)',
      licenseOrAccess: 'MIT Open-Source — Intégré en direct ici',
      summary: 'Définitions anglaises, phonétique IPA, exemples réels et prononciations MP3 natives.',
      url: 'https://dictionaryapi.dev/',
    ),
    OpenLearningPortal(
      name: 'Tatoeba Corpus (CC-BY Open Data)',
      licenseOrAccess: 'Licence libre CC-BY',
      summary: 'Milliers de phrases d’exemple bilingues français-anglais avec audio communautaire.',
      url: 'https://tatoeba.org/fr/',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // AMY — PROFESSEURE & PARTENAIRE DE CONVERSATION IA (INSPIRÉ D'ENGLISH AI)
  // ═══════════════════════════════════════════════════════════════════════
  static const List<AmyScenario> amyScenarios = [
    AmyScenario(
      id: 'intro',
      titleFr: 'Se présenter',
      levelRange: 'A1–A2',
      openingAssetPath: 'assets/audio/amy/intro.mp3',
      openingEn:
          "Hello! I'm Amy, your English speaking partner at BOROOM YITTÉ. Let's practise together! Could you introduce yourself and tell me what you study or work on?",
      openingFr:
          'Bonjour ! Je suis Amy, votre partenaire de pratique orale à BOROOM YITTÉ. Présentez-vous en anglais (prénom, études ou métier).',
      followUpsEn: [
        "Nice to meet you! Why did you decide to improve your English this year in 2026?",
        "That is a clear goal. What do you enjoy doing in your free time, or what topics inspire you in BOROOM YITTÉ?",
        "Great progress! How many minutes a day can you commit to speaking English with me?",
        "Wonderful commitment! Let's summarise your routine in two complete English sentences.",
      ],
      sampleTargetEn:
          "Hello Amy, my name is Aminata. I study engineering and I joined BOROOM YITTÉ in 2026 to speak English confidently.",
      suggestedRepliesEn: [
        "Hello Amy! My name is Moussa and I study computer science in Dakar.",
        "Hi Amy, I work in engineering and I joined BOROOM YITTÉ in 2026 to become fluent.",
        "Nice to meet you! I want to practise speaking English for twenty minutes every day.",
      ],
    ),
    AmyScenario(
      id: 'interview',
      titleFr: 'Entretien pro',
      levelRange: 'B1–B2',
      openingAssetPath: 'assets/audio/amy/interview.mp3',
      openingEn:
          "Good morning! I'm Amy, and today I'll be your interviewer. Take a deep breath and answer clearly: Tell me about yourself and one achievement you are proud of.",
      openingFr:
          'Mode entretien réel (méthode STAR). Répondez en présentant votre parcours et une réalisation concrète.',
      followUpsEn: [
        "Thank you. Can you describe a difficult technical or team challenge you faced, and how you solved it?",
        "That shows initiative. What are your main strengths, and one skill you are actively developing right now?",
        "Where do you see yourself in three years, and how does this opportunity fit your long-term vision?",
        "Excellent interview practice! Do you have a thoughtful question to ask me about the team or role?",
      ],
      sampleTargetEn:
          "I am a motivated graduate with hands-on project experience. Recently, I coordinated a team task and delivered results ahead of schedule.",
      suggestedRepliesEn: [
        "I am a dedicated engineer who enjoys solving practical problems with my team.",
        "Last year, I led a project where we reduced delays by thirty percent.",
        "One strength I bring is clear communication, and I am currently sharpening my leadership skills.",
      ],
    ),
    AmyScenario(
      id: 'daily',
      titleFr: 'Vie quotidienne',
      levelRange: 'A2–B1',
      openingAssetPath: 'assets/audio/amy/daily.mp3',
      openingEn:
          "Hi! It's Amy. Imagine we just met at a café in London after a conference. How was your morning, and what would you like to order?",
      openingFr:
          'Mise en situation naturelle (café, voyage, politesse anglaise : "Could I have...", "I would like...").',
      followUpsEn: [
        "Good choice! By the way, how did you get here today — did you take the train or walk?",
        "If you had to ask a stranger for directions to the nearest library politely, what would you say?",
        "Imagine your flight is delayed by two hours. How would you ask the desk agent for an update?",
        "You sounded very polite and natural! What everyday situation would you like to practise next?",
      ],
      sampleTargetEn:
          "Good morning! My morning was busy but productive. Could I have a green tea and a bottle of water, please?",
      suggestedRepliesEn: [
        "My morning was great, thank you! Could I have a cup of tea and a croissant, please?",
        "I walked here because the weather is lovely today.",
        "Excuse me, could you tell me how to get to the nearest library?",
      ],
    ),
    AmyScenario(
      id: 'project',
      titleFr: 'Présenter un projet',
      levelRange: 'B2',
      openingAssetPath: 'assets/audio/amy/project.mp3',
      openingEn:
          "Welcome back! I'm Amy. Pitch me a real project you care about — in science, agriculture, tech, medicine or business. What problem does it solve?",
      openingFr:
          'Présentez un projet concret en 3 temps : Problème → Solution → Impact attendu.',
      followUpsEn: [
        "Interesting concept! Who benefits directly from your project, and what makes your approach practical?",
        "What is the biggest obstacle or risk right now, and how do you plan to overcome it?",
        "Suppose you only have 30 seconds to convince a partner to support this project. Give me your key message!",
        "Very structured pitch! Notice how clear transitions make technical ideas easy to follow.",
      ],
      sampleTargetEn:
          "Our project addresses water waste in agriculture by using low-cost moisture sensors to optimise irrigation schedules.",
      suggestedRepliesEn: [
        "Our project helps local farmers save water using simple moisture sensors.",
        "We are building a mobile learning platform to help students master English and technology.",
        "The main challenge is funding, so we are starting with a small pilot group first.",
      ],
    ),
    AmyScenario(
      id: 'debate',
      titleFr: 'Débat & Nuance',
      levelRange: 'C1',
      openingAssetPath: 'assets/audio/amy/debate.mp3',
      openingEn:
          "Hello! Amy here for our C1 speaking seminar. Here is today's motion: Does artificial intelligence strengthen or weaken human critical thinking? Give me a nuanced stance.",
      openingFr:
          'Exprimez une thèse nuancée en utilisant des connecteurs (Although, Nevertheless, Provided that, Granted).',
      followUpsEn: [
        "Fair point. However, what would you reply to someone who argues that instant answers reduce deep reading?",
        "Interesting nuance. Can you illustrate your argument with a concrete example from education or research?",
        "To conclude our debate, what single principle should guide young scholars using technology wisely?",
        "Impressive reasoning! Your discourse markers gave real rhythm and precision to your argument.",
      ],
      sampleTargetEn:
          "Although AI accelerates research, it only strengthens critical thinking provided that learners actively verify every claim.",
      suggestedRepliesEn: [
        "Although AI saves time, it can weaken critical thinking if students stop verifying sources.",
        "On balance, technology is a powerful tool provided that we keep human judgment at the centre.",
        "For example, in research, AI can draft summaries, yet only careful reading builds true expertise.",
      ],
    ),
    AmyScenario(
      id: 'shadowing',
      titleFr: 'Prononciation',
      levelRange: 'Tous niveaux',
      openingAssetPath: 'assets/audio/amy/shadowing.mp3',
      openingEn:
          "Hi! Let's train your pronunciation together with shadowing. Listen carefully and repeat aloud: 'Although three thoughtful thinkers worked through the afternoon, they remained thoroughly focused.'",
      openingFr:
          'Travail ciblé sur les sons pièges francophones : "th" (/θ/ et /ð/), "h" expiré et terminaisons "-ed". Écoutez Amy puis répétez au micro !',
      followUpsEn: [
        "Great effort! Now focus on the aspirated 'H' — repeat after me: 'Henry hopes his honest habits help him handle hard challenges.'",
        "Now let's practise '-ed' endings (/t/, /d/, /ɪd/): 'We worked hard, learned fast, and decided to improve every day.'",
        "Now word stress: 'We must de-VE-lop a clear PRO-ject and pre-SENT our re-SULTS with con-fi-dence.'",
        "Brilliant pronunciation workout! Daily 5-minute shadowing with Amy transforms your clarity in weeks.",
      ],
      sampleTargetEn:
          "Although three thoughtful thinkers worked through the afternoon, they remained thoroughly focused.",
      suggestedRepliesEn: [
        "Although three thoughtful thinkers worked through the afternoon, they remained thoroughly focused.",
        "Henry hopes his honest habits help him handle hard challenges.",
        "We worked hard, learned fast, and decided to improve every day.",
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // PROGRAMME RIGOUREUX 12 SEMAINES (MÉTHODE CELTA / CAMBRIDGE — 4 COMPÉTENCES)
  // ═══════════════════════════════════════════════════════════════════════
  static const List<TwelveWeekPhase> twelveWeekMasteryPlan = [
    TwelveWeekPhase(
      phaseCode: 'Semaines 1–2',
      cefr: 'A1 → A2',
      title: 'Fondations, Sons Pièges & Automatisme Oral',
      dailyRoutineFr:
          '30 min/j : 5 min Shadowing avec Amy • 10 min Grammaire A1 • 10 min Dialogue "Se présenter" • 5 min 5 phrases écrites.',
      listeningGoal: 'Comprendre des présentations lentes (0.8x) et identifier les mots-clés.',
      speakingGoal: 'Se présenter 90 secondes sans blocage avec Amy (identité, parcours, 2026).',
      readingGoal: 'Lire des textes courts et comprendre la structure Sujet + Verbe + Complément.',
      writingGoal: 'Rédiger 8 phrases exactes sans erreur d’auxiliaire (do/does/to be).',
    ),
    TwelveWeekPhase(
      phaseCode: 'Semaines 3–4',
      cefr: 'A2+ → B1',
      title: 'Récit au Passé, Projets Futurs & Politesse',
      dailyRoutineFr:
          '30 min/j : 10 min Cours A2 (Past Simple, Going to, Can/Could) • 10 min Scénario "Vie quotidienne" avec Amy • 10 min Verbes irréguliers.',
      listeningGoal: 'Saisir les informations clés d’un dialogue quotidien (VOA / BBC).',
      speakingGoal: 'Raconter une journée ou demander un service poliment avec Amy.',
      readingGoal: 'Lire un article court en anglais en utilisant le Dictionnaire MIT intégré.',
      writingGoal: 'Rédiger un paragraphe narratif au passé sans confondre "did + base verbale".',
    ),
    TwelveWeekPhase(
      phaseCode: 'Semaines 5–6',
      cefr: 'B1',
      title: 'Present Perfect, For/Since & Faux Amis FR→EN',
      dailyRoutineFr:
          '35 min/j : 10 min Cours B1 • 10 min Correction LanguageTool sur un texte libre • 15 min Conversation libre avec Amy.',
      listeningGoal: 'Suivre une émission "6 Minute English" (BBC) avec script vérifié.',
      speakingGoal: 'Tenir un échange de 5 tours continus avec Amy sans repasser au français.',
      readingGoal: 'Repérer les faux amis (actually, library, sensible, attend, resume).',
      writingGoal: 'Produire 120 mots sur un sujet d’actualité vérifiés à <2 fautes.',
    ),
    TwelveWeekPhase(
      phaseCode: 'Semaines 7–8',
      cefr: 'B2',
      title: 'Anglais Professionnel, Entretiens STAR & Projets',
      dailyRoutineFr:
          '40 min/j : 10 min Cours B2 (Conditionnels & Phrasal Verbs) • 15 min Scénario "Entretien pro" ou "Projet" avec Amy • 15 min Pitch oral évalué.',
      listeningGoal: 'Comprendre une présentation professionnelle ou technique à vitesse normale.',
      speakingGoal: 'Répondre à 4 questions d’entretien STAR et pitcher un projet en 2 min.',
      readingGoal: 'Lire une offre d’emploi, une documentation technique ou un rapport.',
      writingGoal: 'Écrire un email professionnel et une présentation de projet structurée.',
    ),
    TwelveWeekPhase(
      phaseCode: 'Semaines 9–10',
      cefr: 'C1',
      title: 'Argumentation Nuancée, Synthèse & Discours Académique',
      dailyRoutineFr:
          '40 min/j : 10 min Cours C1 (Concession, Passif avancé) • 15 min Scénario "Débat & Nuance" avec Amy • 15 min Essai argumenté.',
      listeningGoal: 'Analyser des débats et conférences complexes en relevant la nuance.',
      speakingGoal: 'Défendre une thèse et répondre aux contre-arguments avec fluidité.',
      readingGoal: 'Synthétiser un article scientifique ou philosophique en 5 points clés.',
      writingGoal: 'Rédiger un essai structuré de 250 mots avec connecteurs C1.',
    ),
    TwelveWeekPhase(
      phaseCode: 'Semaines 11–12',
      cefr: 'C2',
      title: 'Fluidité Naturelle, Idiomes & Autonomie Totale',
      dailyRoutineFr:
          '45 min/j : 10 min Shadowing vitesse native avec Amy • 20 min Débat improvisé 3 min • 15 min Lecture & reformulation idiomatique.',
      listeningGoal: 'Comprendre l’anglais authentique (UK & US) y compris l’implicite.',
      speakingGoal: 'Parler 3 minutes en continu sur un thème tiré au sort avec score >85/100.',
      readingGoal: 'Lire des ouvrages et essais complexes sans traduction mentale.',
      writingGoal: 'Écrire avec précision stylistique, concision et registre adapté.',
    ),
  ];

  /// Évalue une phrase répétée à voix haute (Shadowing façon English AI) mot par mot.
  static ShadowingEvaluation evaluateShadowing({
    required String targetSentence,
    required String spokenText,
  }) {
    String cleanWord(String w) =>
        w.toLowerCase().replaceAll(RegExp(r"[^a-z0-9']"), '');

    final rawTarget = targetSentence
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => cleanWord(w).isNotEmpty)
        .toList();
    final spokenSet = spokenText
        .trim()
        .split(RegExp(r'\s+'))
        .map(cleanWord)
        .where((w) => w.isNotEmpty)
        .toSet();

    if (rawTarget.isEmpty) {
      return const ShadowingEvaluation(
        scorePercent: 0,
        wordResults: [],
        feedbackFr: 'Sélectionnez une phrase à répéter.',
      );
    }

    int matched = 0;
    final results = <ShadowingWordResult>[];
    for (final raw in rawTarget) {
      final norm = cleanWord(raw);
      final hit = spokenSet.contains(norm) ||
          (norm.length >= 4 &&
              spokenSet.any(
                (s) => s.startsWith(norm.substring(0, norm.length - 1)),
              ));
      if (hit) matched++;
      results.add(ShadowingWordResult(word: raw, matched: hit));
    }

    final pct = ((matched / rawTarget.length) * 100).round().clamp(0, 100);
    final feedback = pct >= 90
        ? 'Excellente fluidité ($pct%) ! Prononciation très claire et rythme naturel.'
        : pct >= 70
            ? 'Bon rythme ($pct%) ! Répétez les mots surlignés en or en mode lent (0.8×) pour affiner l’articulation.'
            : 'Bien essayé ($pct%) ! Écoutez Amy en mode lent puis répétez par petits groupes de 3–4 mots.';

    return ShadowingEvaluation(
      scorePercent: pct,
      wordResults: results,
      feedbackFr: feedback,
    );
  }

  static const AmyScenario freeDiscussionScenario = AmyScenario(
    id: 'free',
    titleFr: 'Discussion libre',
    levelRange: 'A1–C2',
    openingAssetPath: 'assets/audio/amy/intro.mp3',
    openingEn:
        "Hello! I'm Amy, your English conversation coach. Talk to me about anything you like — your day, your studies, your projects, or ask me how to say something in English. What is on your mind today?",
    openingFr:
        'Discussion totalement libre avec Amy ! Parlez de n’importe quel sujet (votre journée, travail, études, projets) ou demandez-lui comment dire une phrase en anglais. Amy adapte son vocabulaire à votre niveau.',
    followUpsEn: [
      "Tell me more about that! What happened next, or why is it important to you?",
      "That's really interesting! How do you usually handle that in your daily routine?",
      "Great point! What goal would you like to achieve next in 2026?",
      "You're expressing yourself more smoothly! What else would you like to talk about today?",
    ],
    sampleTargetEn:
        "Hello Amy! Today I want to talk about my projects and practise speaking English fluently.",
    suggestedRepliesEn: [
      "Hello Amy! Today was a busy day and I want to practise speaking English with you.",
      "I am studying right now and I want to improve my English for international opportunities.",
      "Could you help me practise talking about my daily routine and my goals for 2026?",
    ],
  );

  static const List<String> cefrLevelsOrdered = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  static String? nextCefrLevel(String current) {
    final idx = cefrLevelsOrdered.indexOf(current.toUpperCase());
    if (idx < 0 || idx >= cefrLevelsOrdered.length - 1) return null;
    return cefrLevelsOrdered[idx + 1];
  }

  static String cefrStyleGuide(String cefrLevel) {
    return switch (cefrLevel.toUpperCase()) {
      'A1' =>
        'CEFR A1 (Beginner): use very short, clear sentences (6-10 words), basic everyday vocabulary, present simple, and warm encouragement.',
      'A2' =>
        'CEFR A2 (Elementary): use simple connected sentences, daily routines, past simple & going-to future, and polite everyday expressions.',
      'B1' =>
        'CEFR B1 (Intermediate): speak naturally about work, studies, and experiences; reinforce Present Perfect, for/since, and connectors (because, although, however).',
      'B2' =>
        'CEFR B2 (Upper-Intermediate): use confident professional/academic phrasing, phrasal verbs, conditionals, and thoughtful follow-up questions.',
      'C1' =>
        'CEFR C1 (Advanced): use nuanced discourse markers (nevertheless, provided that, albeit), idioms, and precise stylistic upgrades.',
      _ =>
        'CEFR C2 (Mastery): engage at executive/scholarly fluency with subtle rhetoric, concise idioms, and refined register coaching.',
    };
  }

  static ({String en, String fr}) openingForLevel(
    AmyScenario scenario,
    String cefrLevel,
  ) {
    if (scenario.id != 'free') {
      return (en: scenario.openingEn, fr: scenario.openingFr);
    }
    return switch (cefrLevel.toUpperCase()) {
      'A1' => (
          en: "Hello! I am Amy. We can talk slowly in simple English. How are you today, and what is your name?",
          fr: 'Niveau A1 (Débutant) : Amy utilise des phrases courtes et simples. Répondez librement en anglais !',
        ),
      'A2' => (
          en: "Hi! I'm Amy, your English speaking partner. Tell me about your day or what you did yesterday — I will help you gently!",
          fr: 'Niveau A2 (Élémentaire) : parlez de votre journée, de vos activités ou posez une question libre.',
        ),
      'B2' => (
          en: "Hello! I'm Amy, your B2 speaking coach. Let's have a real conversation about your work, studies, or any topic on your mind today — what would you like to discuss?",
          fr: 'Niveau B2 (Avancé) : échange naturel, phrasal verbs, conditionnels et reformulations professionnelles.',
        ),
      'C1' || 'C2' => (
          en: "Welcome back! I'm Amy. At level $cefrLevel, let's dive into any nuanced topic you choose — career, ideas, technology, or society. What perspective would you like to explore today?",
          fr: 'Niveau $cefrLevel (Maîtrise) : argumentation nuancée, expressions idiomatiques et précision stylistique.',
        ),
      _ => (en: scenario.openingEn, fr: scenario.openingFr),
    };
  }

  /// Appelle le modèle conversationnel ouvert (Pollinations OpenAI-compatible, CORS *) pour une vraie discussion en direct avec Amy.
  Future<AmyTurnReply?> _converseWithAmyLiveAi({
    required String userInput,
    required AmyScenario scenario,
    required String variant,
    required String cefrLevel,
    required List<({bool fromAmy, String text})> history,
    required LanguageToolCheckResult grammarCheck,
  }) async {
    try {
      final levelGuide = cefrStyleGuide(cefrLevel);
      final targetUpgradeLevel = nextCefrLevel(cefrLevel) ?? 'C2';
      final accentNote = variant == 'en-GB'
          ? 'British English spelling and natural UK phrasing'
          : 'American English spelling and natural US phrasing';
      final topicContext = scenario.id == 'free'
          ? 'Open free conversation: respond directly to whatever topic or question the learner brings up.'
          : 'Scenario "${scenario.titleFr}" (${scenario.levelRange}): stay natural and directly answer what the learner actually wrote.';

      final systemPrompt =
          'You are Amy, a warm, natural, friendly English speaking partner (like Learna AI) chatting with a francophone learner at CEFR level $cefrLevel. '
          '$levelGuide Use $accentNote. $topicContext '
          'CRITICAL STYLE RULES: '
          '1) Keep amy_reply_en 100% natural, human, in-character conversation (2-3 short fluent sentences): genuinely react to what the learner actually said, share a brief natural thought, and ask ONE engaging open-ended follow-up question. '
          '2) NEVER lecture or mention grammar rules inside amy_reply_en — put ALL corrections and explanations ONLY inside corrected_en and explanation_fr. '
          '3) If the learner writes in French or asks how to say something in English, gently give them the natural English phrasing in amy_reply_en and keep the conversation flowing naturally in English. '
          'Return ONLY valid compact JSON (no markdown fences, no extra text) with these exact keys:\n'
          '{"amy_reply_en":"Natural in-character English reply (2-3 sentences) ending with 1 engaging question",'
          '"translation_fr":"Accurate natural French translation of amy_reply_en",'
          '"corrected_en":"Corrected English version of the learner message with ALL grammar/spelling errors fixed, or empty string if already natural and error-free",'
          '"explanation_fr":"1 short clear French tip explaining the correction (or brief praise if natural)",'
          '"native_upgrade_en":"How a fluent speaker at level $targetUpgradeLevel would express the learner exact idea naturally",'
          '"fluency_score":82,'
          '"estimated_cefr":"A1|A2|B1|B2|C1|C2",'
          '"suggested_replies_en":["Short natural first-person reply 1 the student can say next","Short natural first-person reply 2","Short natural first-person reply 3"]}';

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
      ];
      final recent = history.length > 6
          ? history.sublist(history.length - 6)
          : history;
      for (final h in recent) {
        messages.add({
          'role': h.fromAmy ? 'assistant' : 'user',
          'content': h.text,
        });
      }
      messages.add({'role': 'user', 'content': userInput});

      final res = await http
          .post(
            Uri.parse('https://text.pollinations.ai/openai'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'openai',
              'temperature': 0.55,
              'messages': messages,
            }),
          )
          .timeout(const Duration(seconds: 11));

      if (res.statusCode != 200) return null;
      final outer = jsonDecode(res.body);
      if (outer is! Map<String, dynamic>) return null;
      final choices = outer['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final content =
          (choices.first as Map<String, dynamic>)['message']?['content']
              ?.toString()
              .trim();
      if (content == null || content.isEmpty) return null;

      // Strip optional ```json ... ``` wrappers cleanly
      var jsonStr = content;
      final firstBrace = jsonStr.indexOf('{');
      final lastBrace = jsonStr.lastIndexOf('}');
      if (firstBrace >= 0 && lastBrace > firstBrace) {
        jsonStr = jsonStr.substring(firstBrace, lastBrace + 1);
      }

      final parsed = jsonDecode(jsonStr);
      if (parsed is! Map<String, dynamic>) return null;

      final amyReplyEn = (parsed['amy_reply_en'] ?? '').toString().trim();
      if (amyReplyEn.isEmpty) return null;

      final translationFr = (parsed['translation_fr'] ?? '').toString().trim();
      var correctedEn = (parsed['corrected_en'] ?? '').toString().trim();
      final explanationFr = (parsed['explanation_fr'] ?? '').toString().trim();
      final nativeUpgrade = (parsed['native_upgrade_en'] ?? '').toString().trim();
      final rawScore = parsed['fluency_score'];
      final fluencyScore = (rawScore is num ? rawScore.round() : 82).clamp(45, 99);
      final rawCefr = (parsed['estimated_cefr'] ?? cefrLevel)
          .toString()
          .trim()
          .toUpperCase();
      final estimatedCefr =
          cefrLevelsOrdered.contains(rawCefr) ? rawCefr : cefrLevel;

      final rawSug = parsed['suggested_replies_en'];
      final suggestions = rawSug is List
          ? rawSug
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .take(3)
              .toList()
          : <String>[];

      // Cross-check with LanguageTool if LLM echoed original text with known grammar error
      if ((correctedEn.isEmpty ||
              correctedEn.toLowerCase() == userInput.toLowerCase()) &&
          grammarCheck.issues.isNotEmpty) {
        correctedEn = grammarCheck.correctedText;
      }
      final hasCorrection = correctedEn.isNotEmpty &&
          correctedEn.toLowerCase() != userInput.toLowerCase();

      String? correctionNote;
      if (explanationFr.isNotEmpty) {
        correctionNote = hasCorrection
            ? 'Coaching d’Amy ($cefrLevel) : $explanationFr\nVersion corrigée : "$correctedEn"'
            : 'Coaching d’Amy ($cefrLevel) : $explanationFr';
      } else if (hasCorrection) {
        correctionNote = 'Correction d’Amy : "$correctedEn"';
      }

      return AmyTurnReply(
        amySpeechEn: amyReplyEn,
        amyTranslationFr: translationFr.isNotEmpty
            ? translationFr
            : 'Amy vous a répondu en direct selon votre niveau $cefrLevel.',
        correctionNote: correctionNote,
        correctedText: hasCorrection ? correctedEn : null,
        nativeUpgrade: nativeUpgrade.isNotEmpty ? nativeUpgrade : null,
        nextPromptEn: amyReplyEn,
        fluencyScore: fluencyScore,
        estimatedCefr: estimatedCefr,
        usedLiveAi: true,
        suggestedRepliesEn: suggestions.isNotEmpty
            ? suggestions
            : _buildFollowUpHints(scenario.id, 0),
      );
    } catch (_) {
      return null;
    }
  }

  /// Moteur de conversation multi-tours avec Amy (IA conversationnelle en direct adaptée au niveau CEFR + repli hors-ligne intelligent).
  Future<AmyTurnReply> converseWithAmy({
    required String userInput,
    required AmyScenario scenario,
    required int turnIndex,
    required String variant,
    required String cefrLevel,
    List<({bool fromAmy, String text})> history = const [],
  }) async {
    final trimmed = userInput.trim();
    if (trimmed.isEmpty) {
      final opening = openingForLevel(scenario, cefrLevel);
      return AmyTurnReply(
        amySpeechEn: opening.en,
        amyTranslationFr: opening.fr,
        correctionNote: null,
        correctedText: null,
        nativeUpgrade: null,
        nextPromptEn: opening.en,
        fluencyScore: 0,
        estimatedCefr: cefrLevel,
        usedLiveAi: false,
        suggestedRepliesEn: scenario.suggestedRepliesEn,
      );
    }

    final check = await checkGrammarLive(trimmed, language: variant);

    // 1. Vraie discussion IA en direct (Pollinations OpenAI-compatible, CORS *, adaptée au niveau CEFR)
    final liveReply = await _converseWithAmyLiveAi(
      userInput: trimmed,
      scenario: scenario,
      variant: variant,
      cefrLevel: cefrLevel,
      history: history,
      grammarCheck: check,
    );
    if (liveReply != null) {
      return liveReply;
    }

    // 2. Repli hors-ligne intelligent calibré au niveau CEFR (A1 → C2)
    final hasIssues = check.issues.isNotEmpty;
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final lower = trimmed.toLowerCase();
    final engineLabel = check.usedOnlineApi
        ? 'LanguageTool en direct'
        : 'Correcteur FR→EN';

    int score = 74;
    if (words >= 8) score += 8;
    if (words >= 15) score += 6;
    if (RegExp(r'\b(because|although|however|therefore|actually|currently|finally|for example|nevertheless|provided)\b')
        .hasMatch(lower)) {
      score += 7;
    }
    score -= (check.issues.length * 8);
    if (words < 4) score -= 14;
    final fluencyScore = score.clamp(45, 99);

    final estimatedCefr = fluencyScore >= 90 && words >= 14
        ? (nextCefrLevel(cefrLevel) ?? 'C2')
        : (fluencyScore < 62 ? 'A2' : cefrLevel);

    String? correctionNote;
    if (hasIssues) {
      final firstIssues = check.issues.take(3).map((i) {
        final repl = i.replacements.isNotEmpty ? i.replacements.first : '...';
        return '« ${i.badText} » → « $repl » (${i.message})';
      }).join('\n• ');
      correctionNote =
          'Correction d’Amy ($engineLabel • $cefrLevel) :\n• $firstIssues\nPhrase corrigée : "${check.correctedText}"';
    } else if (words < 5) {
      correctionNote =
          'Conseil d’Amy ($cefrLevel) : phrase correcte ! Développez avec « because... » ou un exemple concret pour progresser vers ${nextCefrLevel(cefrLevel) ?? "C2"}.';
    }

    final upgraded = _buildNativeUpgrade(check.correctedText, scenario.id);
    final followUp = scenario.followUpsEn.isNotEmpty
        ? scenario.followUpsEn[turnIndex % scenario.followUpsEn.length]
        : "That's very interesting! Could you tell me a bit more about that?";

    String contextualAck;
    if (lower.contains('comment dire') || lower.contains('how do i say')) {
      contextualAck =
          "Great question! Try expressing the idea simply in English first, and I will polish it to natural $cefrLevel English for you.";
    } else if (hasIssues) {
      contextualAck = cefrLevel == 'A1' || cefrLevel == 'A2'
          ? "Good try! You can say: \"${check.correctedText}\"."
          : "I understood you clearly — a smooth way to say that is: \"${check.correctedText}\".";
    } else if (lower.contains('engineer') ||
        lower.contains('tech') ||
        lower.contains('computer') ||
        lower.contains('developer')) {
      contextualAck =
          "That sounds fascinating! Speaking English clearly will open huge international opportunities in tech and engineering.";
    } else if (lower.contains('agronom') ||
        lower.contains('farm') ||
        lower.contains('water') ||
        lower.contains('environment')) {
      contextualAck =
          "What an impactful field! Clear English helps share agricultural innovation worldwide.";
    } else if (lower.contains('doctor') ||
        lower.contains('medicine') ||
        lower.contains('health') ||
        lower.contains('student')) {
      contextualAck =
          "Wonderful! Your dedication to your studies and to BOROOM YITTÉ really shines through.";
    } else if (lower.contains('2026') || lower.contains('boroom')) {
      contextualAck =
          "I love that! Joining BOROOM YITTÉ in 2026 with a daily speaking habit is a brilliant decision.";
    } else if (words >= 12) {
      contextualAck =
          "Well expressed! Your rhythm and sentence structure sounded very natural for level $cefrLevel.";
    } else {
      contextualAck = "Good, clear answer!";
    }

    final amySpeechEn = '$contextualAck $followUp';
    final amyTranslationFr = hasIssues
        ? 'Amy vous a bien compris, vous propose une formulation plus fluide ($cefrLevel) et relance la conversation.'
        : 'Très bien exprimé (Fluidité $fluencyScore/100 • Niveau $estimatedCefr) ! Amy poursuit l’échange en anglais.';

    final nextSuggestions = _buildFollowUpHints(scenario.id, turnIndex);

    return AmyTurnReply(
      amySpeechEn: amySpeechEn,
      amyTranslationFr: amyTranslationFr,
      correctionNote: correctionNote,
      correctedText: hasIssues ? check.correctedText : null,
      nativeUpgrade: upgraded,
      nextPromptEn: followUp,
      fluencyScore: fluencyScore,
      estimatedCefr: estimatedCefr,
      usedLiveAi: false,
      suggestedRepliesEn: nextSuggestions,
    );
  }

  List<String> _buildFollowUpHints(String scenarioId, int turnIndex) {
    return switch (scenarioId) {
      'interview' => const [
          'In that situation, I analysed the bottleneck, coordinated with teammates, and solved it in two days.',
          'My biggest strength is consistency, and right now I am sharpening my public speaking in English.',
          'In three years, I aim to lead impactful projects while mentoring younger colleagues.',
        ],
      'daily' => const [
          'I took the bus this morning, and the trip was smooth and pleasant.',
          'Excuse me, could you please tell me the quickest way to the central library?',
          'Could you let me know when the next update about our boarding gate will be announced?',
        ],
      'project' => const [
          'Local students and communities benefit directly because the tool works even with low connectivity.',
          'Our main risk is adoption, so we are testing early feedback with real users every week.',
          'In short, our solution cuts waste by thirty percent while staying affordable and simple to maintain.',
        ],
      'debate' => const [
          'That is a valid concern; however, guided critical reading paired with AI can deepen understanding.',
          'For instance, when students verify AI summaries against original texts, they retain far more knowledge.',
          'Above all, young scholars should treat AI as an assistant rather than a substitute for thinking.',
        ],
      'shadowing' => const [
          'Henry hopes his honest habits help him handle hard challenges.',
          'We worked hard, learned fast, and decided to improve every day.',
          'We must develop a clear project and present our results with confidence.',
        ],
      _ => [
          'I decided to improve my English in 2026 to communicate confidently in international projects.',
          'In my free time, I enjoy reading, learning new skills, and debating ideas with BOROOM YITTÉ.',
          'I can commit twenty-five minutes every morning to listening and speaking aloud with you.',
        ],
    };
  }

  String? _buildNativeUpgrade(String cleanText, String scenarioId) {
    final lower = cleanText.toLowerCase();
    if (lower.length < 12) return null;
    if (lower.startsWith('i think ')) {
      return 'From my perspective, ${cleanText.substring(8)}';
    }
    if (lower.startsWith('i want to ')) {
      return 'I aim to ${cleanText.substring(10)}';
    }
    if (lower.startsWith('my name is ')) {
      return '$cleanText, and I am delighted to practise with you today.';
    }
    if (scenarioId == 'interview' && !lower.contains('result')) {
      return 'In that role, $cleanText — which produced a measurable outcome for the team.';
    }
    if (scenarioId == 'debate' && !lower.contains('however') && !lower.contains('although')) {
      return 'While there are valid counterarguments, $cleanText';
    }
    return null;
  }
}

class AmyScenario {
  final String id;
  final String titleFr;
  final String levelRange;
  final String openingAssetPath;
  final String openingEn;
  final String openingFr;
  final List<String> followUpsEn;
  final String sampleTargetEn;
  final List<String> suggestedRepliesEn;

  const AmyScenario({
    required this.id,
    required this.titleFr,
    required this.levelRange,
    required this.openingAssetPath,
    required this.openingEn,
    required this.openingFr,
    required this.followUpsEn,
    required this.sampleTargetEn,
    required this.suggestedRepliesEn,
  });
}

class AmyTurnReply {
  final String amySpeechEn;
  final String amyTranslationFr;
  final String? correctionNote;
  final String? correctedText;
  final String? nativeUpgrade;
  final String nextPromptEn;
  final int fluencyScore;
  final String estimatedCefr;
  final bool usedLiveAi;
  final List<String> suggestedRepliesEn;

  const AmyTurnReply({
    required this.amySpeechEn,
    required this.amyTranslationFr,
    this.correctionNote,
    this.correctedText,
    this.nativeUpgrade,
    required this.nextPromptEn,
    this.fluencyScore = 85,
    this.estimatedCefr = 'B1',
    this.usedLiveAi = false,
    this.suggestedRepliesEn = const [],
  });
}

class ShadowingWordResult {
  final String word;
  final bool matched;

  const ShadowingWordResult({required this.word, required this.matched});
}

class ShadowingEvaluation {
  final int scorePercent;
  final List<ShadowingWordResult> wordResults;
  final String feedbackFr;

  const ShadowingEvaluation({
    required this.scorePercent,
    required this.wordResults,
    required this.feedbackFr,
  });
}

class TwelveWeekPhase {
  final String phaseCode;
  final String cefr;
  final String title;
  final String dailyRoutineFr;
  final String listeningGoal;
  final String speakingGoal;
  final String readingGoal;
  final String writingGoal;

  const TwelveWeekPhase({
    required this.phaseCode,
    required this.cefr,
    required this.title,
    required this.dailyRoutineFr,
    required this.listeningGoal,
    required this.speakingGoal,
    required this.readingGoal,
    required this.writingGoal,
  });
}
