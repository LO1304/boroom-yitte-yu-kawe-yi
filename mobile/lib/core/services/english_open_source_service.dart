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

/// Integrates the MIT open-source Free Dictionary API (dictionaryapi.dev / Wiktionary)
/// together with a structured A1 -> C2 procedural syllabus, irregular verbs, and verified
/// free educational portals.
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
      name: 'Free Dictionary API (Open-Source MIT / Wiktionary)',
      licenseOrAccess: 'MIT Open-Source — Intégré en direct ici',
      summary: 'Définitions anglaises, phonétique IPA, exemples réels et prononciations MP3 natives.',
      url: 'https://dictionaryapi.dev/',
    ),
    OpenLearningPortal(
      name: 'British Council LearnEnglish (A1 → C1)',
      licenseOrAccess: 'Accès gratuit officiel',
      summary: 'Parcours structurés par compétence : Listening, Reading, Speaking, Grammar.',
      url: 'https://learnenglish.britishcouncil.org/',
    ),
    OpenLearningPortal(
      name: 'BBC Learning English (6 Minute English & Grammar)',
      licenseOrAccess: 'Accès gratuit éducatif',
      summary: 'Audio hebdomadaire avec script complet, phonétique britannique et quiz progressifs.',
      url: 'https://www.bbc.co.uk/learningenglish',
    ),
    OpenLearningPortal(
      name: 'Tatoeba Corpus (CC-BY Open Data)',
      licenseOrAccess: 'Licence libre CC-BY',
      summary: 'Milliers de phrases d’exemple bilingues français-anglais avec audio communautaire.',
      url: 'https://tatoeba.org/fr/',
    ),
  ];
}
