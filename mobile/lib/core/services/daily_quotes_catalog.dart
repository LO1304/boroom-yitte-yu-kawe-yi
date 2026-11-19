class DailyWisdomQuote {
  final String id;
  final String text;
  final String author;
  final String sourceWork;
  final String category; // masalik | ghazali | philosophers

  const DailyWisdomQuote({
    required this.id,
    required this.text,
    required this.author,
    required this.sourceWork,
    required this.category,
  });

  String formatForShare() =>
      '« $text »\n— $author ($sourceWork)\n\nPartagé depuis BOROOM YITTÉ YU KAWÉ YI';
}

/// Curated, verified classical wisdom quotes for daily reflection & sharing:
/// Cheikh Ahmadou Bamba (Masālik al-Jinān), Imām al-Ghazālī (Iḥyāʾ / Ayyuhā al-Walad),
/// Épictète (Manuel), Sénèque (Lettres à Lucilius), Épicure (Lettre à Ménécée).
class DailyQuotesCatalog {
  const DailyQuotesCatalog._();

  static const List<DailyWisdomQuote> quotes = [
    // --- Cheikh Ahmadou Bamba : Masālik al-Jinān (Les Itinéraires du Paradis) ---
    DailyWisdomQuote(
      id: 'mj-1',
      text:
          'Il est obligatoire à l’homme de commencer par la science du Fiqh avant d’aborder la voie spirituelle, et de les réunir toutes deux afin d’atteindre la récompense véritable.',
      author: 'Cheikh Ahmadou Bamba',
      sourceWork: 'Masālik al-Jinān (Les Itinéraires du Paradis)',
      category: 'masalik',
    ),
    DailyWisdomQuote(
      id: 'mj-2',
      text:
          'La longanimité et la patience à endurer la peine dans l’adoration du Clément, dans l’adversité et face aux tentations de la désobéissance élèvent le serviteur aux plus hauts degrés auprès de son Seigneur.',
      author: 'Cheikh Ahmadou Bamba',
      sourceWork: 'Masālik al-Jinān (vers 1228–1236, trad. fr.)',
      category: 'masalik',
    ),
    DailyWisdomQuote(
      id: 'mj-3',
      text:
          'Ne cesse de louer le Seigneur et de reconnaître qu’il n’est de force ni de puissance en dehors de Lui ; sois constant dans la gratitude (Chukr) envers le Donateur suprême.',
      author: 'Cheikh Ahmadou Bamba',
      sourceWork: 'Masālik al-Jinān (vers 1227, trad. fr.)',
      category: 'masalik',
    ),
    DailyWisdomQuote(
      id: 'mj-4',
      text:
          'Purifie ton intention de toute recherche de gloire mondaine et d’ostentation (Riyāʾ) ; l’œuvre accomplie pour autre qu’Allah s’écroule comme un édifice bâti sur du sable mouvant.',
      author: 'Cheikh Ahmadou Bamba',
      sourceWork: 'Masālik al-Jinān — Chapitre de la Sincérité',
      category: 'masalik',
    ),
    DailyWisdomQuote(
      id: 'mj-5',
      text:
          'Garde-toi de l’autosatisfaction et de regarder autrui avec mépris : la véritable élévation réside dans la piété discrète et la maîtrise de son âme charnelle (Nafs).',
      author: 'Cheikh Ahmadou Bamba',
      sourceWork: 'Masālik al-Jinān — Purification du cœur',
      category: 'masalik',
    ),

    // --- Imām Abū Ḥāmid al-Ghazālī ---
    DailyWisdomQuote(
      id: 'gh-1',
      text:
          'Plus l’objectif est noble et précieux, plus le chemin qui y mène est difficile, long et semé d’obstacles. Ne pense donc pas que cette quête puisse être menée par de simples souhaits.',
      author: 'Imām Abū Ḥāmid al-Ghazālī',
      sourceWork: 'Iḥyāʾ ʿUlūm ad-Dīn (Revivification des sciences de la foi)',
      category: 'ghazali',
    ),
    DailyWisdomQuote(
      id: 'gh-2',
      text:
          'Ô mon enfant ! La science sans action est une folie, et l’action sans science est stérile.',
      author: 'Imām Abū Ḥāmid al-Ghazālī',
      sourceWork: 'Ayyuhā al-Walad (Lettre au disciple)',
      category: 'ghazali',
    ),
    DailyWisdomQuote(
      id: 'gh-3',
      text:
          'Travaille pour ta vie terrestre proportionnellement au temps que tu dois y passer, et travaille pour ton au-delà proportionnellement à ton éternité là-bas.',
      author: 'Imām Abū Ḥāmid al-Ghazālī',
      sourceWork: 'Ayyuhā al-Walad (Lettre au disciple)',
      category: 'ghazali',
    ),
    DailyWisdomQuote(
      id: 'gh-4',
      text:
          'Si tu exhortes les gens sans mettre en pratique tes propres conseils, tes paroles glisseront sur leurs cœurs comme l’eau glisse sur une roche lisse.',
      author: 'Imām Abū Ḥāmid al-Ghazālī',
      sourceWork: 'Ayyuhā al-Walad (Lettre au disciple)',
      category: 'ghazali',
    ),

    // --- Grands Philosophes (Épictète, Sénèque, Épicure) ---
    DailyWisdomQuote(
      id: 'ph-1',
      text:
          'Ce ne sont pas les événements qui troublent les hommes, mais les jugements qu’ils portent sur les événements.',
      author: 'Épictète',
      sourceWork: 'Manuel (Enchiridion), V',
      category: 'philosophers',
    ),
    DailyWisdomQuote(
      id: 'ph-2',
      text:
          'Parmi les choses qui existent, certaines dépendent de nous, d’autres non. De nous dépendent la pensée, l’impulsion, le désir et l’aversion ; bref, tout ce en quoi c’est nous qui agissons.',
      author: 'Épictète',
      sourceWork: 'Manuel (Enchiridion), I, 1',
      category: 'philosophers',
    ),
    DailyWisdomQuote(
      id: 'ph-3',
      text:
          'Revendique ta propre possession de toi-même ; le temps qui, jusqu’ici, t’était ravi, dérobé ou s’écoulait sans profit, recueille-le et ménage-le.',
      author: 'Sénèque',
      sourceWork: 'Lettres à Lucilius, Lettre I, 1',
      category: 'philosophers',
    ),
    DailyWisdomQuote(
      id: 'ph-4',
      text:
          'Il y a plus de choses qui nous font peur que de choses qui nous font mal ; c’est plus souvent l’opinion que la réalité qui nous met en peine.',
      author: 'Sénèque',
      sourceWork: 'Lettres à Lucilius, Lettre XIII, 4',
      category: 'philosophers',
    ),
    DailyWisdomQuote(
      id: 'ph-5',
      text:
          'Le vrai bonheur ne cherche pas à l’extérieur ses éléments : c’est en nous que nous le cultivons ; c’est de lui-même qu’il sort tout entier.',
      author: 'Sénèque',
      sourceWork: 'Lettres à Lucilius, Lettre LXXII, 6',
      category: 'philosophers',
    ),
    DailyWisdomQuote(
      id: 'ph-6',
      text:
          'Quand on est jeune, il ne faut pas remettre à philosopher, et quand on est vieux il ne faut pas se lasser de philosopher. Car jamais il n’est trop tôt ou trop tard pour travailler à la santé de l’âme.',
      author: 'Épicure',
      sourceWork: 'Lettre à Ménécée, 122',
      category: 'philosophers',
    ),
  ];

  static DailyWisdomQuote quoteForDate(
    DateTime date, {
    String category = 'all',
    int offset = 0,
  }) {
    final pool = category == 'all'
        ? quotes
        : quotes.where((q) => q.category == category).toList();
    if (pool.isEmpty) return quotes.first;
    final daySeed = date.year * 366 + date.month * 31 + date.day;
    final idx = (daySeed + offset) % pool.length;
    return pool[idx < 0 ? idx + pool.length : idx];
  }
}
