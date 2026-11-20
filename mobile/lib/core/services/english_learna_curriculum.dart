import 'english_open_source_service.dart';

class LearnaTopic {
  final String id;
  final String titleFr;
  final String subtitleFr;
  final String levelRange;
  final String openingEn;
  final String openingFr;
  final List<String> followUpsEn;
  final List<String> starterHintsEn;

  const LearnaTopic({
    required this.id,
    required this.titleFr,
    required this.subtitleFr,
    required this.levelRange,
    required this.openingEn,
    required this.openingFr,
    required this.followUpsEn,
    required this.starterHintsEn,
  });

  AmyScenario toAmyScenario() => AmyScenario(
        id: id,
        titleFr: titleFr,
        levelRange: levelRange,
        openingAssetPath: '',
        openingEn: openingEn,
        openingFr: openingFr,
        followUpsEn: followUpsEn,
        sampleTargetEn: starterHintsEn.isNotEmpty ? starterHintsEn.first : '',
        suggestedRepliesEn: starterHintsEn,
      );
}

class LearnaLesson {
  final String id;
  final String level;
  final int unitNumber;
  final String titleFr;
  final String subtitleFr;
  final int durationMin;
  final List<String> coreRules;
  final List<CourseComparisonRow> traps;
  final List<CourseDialogueLine> dialogue;
  final List<CourseQuizItem> quiz;
  final String amyPracticeOpeningEn;
  final String amyPracticeIntroFr;

  const LearnaLesson({
    required this.id,
    required this.level,
    required this.unitNumber,
    required this.titleFr,
    required this.subtitleFr,
    required this.durationMin,
    required this.coreRules,
    required this.traps,
    required this.dialogue,
    required this.quiz,
    required this.amyPracticeOpeningEn,
    required this.amyPracticeIntroFr,
  });
}

class EnglishLearnaCurriculum {
  EnglishLearnaCurriculum._();

  static const List<LearnaTopic> naturalTopics = [
    LearnaTopic(
      id: 'cafe',
      titleFr: 'Café & Rencontre',
      subtitleFr: 'Commander et discuter naturellement',
      levelRange: 'A1–A2',
      openingEn:
          "Hey! Welcome in — it's quite busy this morning, isn't it? What can I get for you, and how has your day been so far?",
      openingFr:
          'Salut ! Bienvenue — il y a du monde ce matin, n’est-ce pas ? Que puis-je vous servir, et comment se passe votre journée jusqu’ici ?',
      followUpsEn: [
        "Great choice! Are you working on anything interesting today, or just taking a relaxing break?",
        "That sounds lovely. Do you usually come to cafés to read or focus, or do you prefer studying at home?",
        "I know what you mean! What are your plans for the rest of the evening?",
      ],
      starterHintsEn: [
        "Hi! Could I have a green tea and a croissant, please? My morning has been busy but good.",
        "Good morning! I'd like a coffee, please. Today I'm taking a short break from my studies.",
        "Hey! A bottle of water would be great, thanks. So far my day is going really well.",
      ],
    ),
    LearnaTopic(
      id: 'daily_life',
      titleFr: 'Ta journée',
      subtitleFr: 'Habitudes, études, travail & loisirs',
      levelRange: 'A1–B1',
      openingEn:
          "Hey! Good to talk to you today. How's your week going so far — have you been busy with work, studies, or personal projects?",
      openingFr:
          'Salut ! Ravi de te parler aujourd’hui. Comment se passe ta semaine jusqu’ici — occupé par le travail, les études ou des projets personnels ?',
      followUpsEn: [
        "That sounds really productive! What part of your day do you enjoy the most?",
        "Interesting! How do you usually unwind and recharge when you have some free time?",
        "If you could pick up one new habit this month, what would it be and why?",
      ],
      starterHintsEn: [
        "My week has been pretty busy! I've been focusing on my studies and practising English every day.",
        "It's going well, thanks! This morning I worked on a project and now I'm taking a break.",
        "Pretty good so far! I'm trying to stay disciplined with my morning routine.",
      ],
    ),
    LearnaTopic(
      id: 'travel',
      titleFr: 'Voyage & Hôtel',
      subtitleFr: 'Aéroport, hôtel & demander son chemin',
      levelRange: 'A2–B1',
      openingEn:
          "Good afternoon and welcome to the hotel! Did you have a smooth trip getting here, and is this your first time visiting the city?",
      openingFr:
          'Bonjour et bienvenue à l’hôtel ! Avez-vous fait bon voyage, et est-ce votre première visite dans cette ville ?',
      followUpsEn: [
        "Glad to hear that! Are you here for work, a conference, or just exploring for a few days?",
        "By the way, would you like any recommendations for good places to eat or visit nearby?",
        "Everything is set for your room! Is there anything else I can help you arrange for tomorrow?",
      ],
      starterHintsEn: [
        "Thank you! The flight was smooth, and yes, it's my very first time visiting this city.",
        "Good afternoon! I had a long trip, so I'm excited to check in and get some rest.",
        "Thanks! I'm here for three nights to attend a conference and explore the neighbourhood.",
      ],
    ),
    LearnaTopic(
      id: 'interview',
      titleFr: 'Entretien pro',
      subtitleFr: 'Parcours, forces & méthode STAR',
      levelRange: 'B1–B2',
      openingEn:
          "Good morning, thanks for making time to speak with me today! To start off, could you walk me through your background and share one achievement you're genuinely proud of?",
      openingFr:
          'Bonjour, merci d’avoir pris le temps de nous parler aujourd’hui ! Pour commencer, pouvez-vous présenter votre parcours et une réalisation dont vous êtes fier ?',
      followUpsEn: [
        "That's impressive. Tell me about a tricky obstacle you ran into on a project — how did you figure out a solution?",
        "Good perspective. What would a colleague say is your biggest strength, and what skill are you actively sharpening right now?",
        "Before we wrap up, what kind of impact do you hope to make in your next role?",
      ],
      starterHintsEn: [
        "Thank you for having me! I have a background in engineering, and recently I led a project that cut delays by 30 percent.",
        "Good morning! I'm a dedicated student who enjoys solving practical problems with a team.",
        "One achievement I'm proud of is organizing a complex deliverable ahead of deadline despite tight constraints.",
      ],
    ),
    LearnaTopic(
      id: 'work_project',
      titleFr: 'Projet & Travail',
      subtitleFr: 'Expliquer une idée clairement en réunion',
      levelRange: 'B2–C1',
      openingEn:
          "Hey, glad we finally caught up! I heard you've been working on an interesting project lately. What problem are you trying to solve, and how is it going so far?",
      openingFr:
          'Salut, content qu’on prenne enfin le temps d’échanger ! J’ai entendu dire que tu travailles sur un projet intéressant. Quel problème cherches-tu à résoudre et où en es-tu ?',
      followUpsEn: [
        "That makes a lot of sense. Who benefits the most from it, and what makes your approach stand out?",
        "Every ambitious project hits roadblocks — what's the toughest challenge you're tackling right now?",
        "If you had 30 seconds to pitch this to a partner, how would you sum up its main value?",
      ],
      starterHintsEn: [
        "We're building a practical tool that helps students learn faster even with limited internet access.",
        "My project focuses on reducing waste in agriculture by tracking soil moisture in real time.",
        "So far we finished the prototype, and now we're gathering honest feedback from early users.",
      ],
    ),
    LearnaTopic(
      id: 'debate',
      titleFr: 'Débat d’idées',
      subtitleFr: 'Argumenter avec nuance et précision',
      levelRange: 'B2–C2',
      openingEn:
          "I was reading something thought-provoking earlier and wanted your honest take: do you think artificial intelligence is making us sharper thinkers, or quietly making us lazier?",
      openingFr:
          'Je lisais un article stimulant tout à l’heure et je voulais ton avis sincère : penses-tu que l’intelligence artificielle rend notre pensée plus affûtée, ou plus paresseuse ?',
      followUpsEn: [
        "Fair point! Though what would you say to someone who argues that instant answers reduce deep reading?",
        "That's a strong nuance. Have you noticed that shift in your own work or studies?",
        "So if you had to set one golden rule for using AI wisely, what would it be?",
      ],
      starterHintsEn: [
        "In my view, it depends on how we use it: AI accelerates research, provided that we still verify every claim.",
        "Although AI saves huge amounts of time, relying on it blindly can definitely weaken critical thinking.",
        "On balance, I see it as a great sparring partner — as long as humans stay responsible for the final judgment.",
      ],
    ),
    LearnaTopic(
      id: 'free',
      titleFr: 'Discussion libre',
      subtitleFr: 'Parlez de ce que vous voulez avec Amy',
      levelRange: 'A1–C2',
      openingEn:
          "Hey! Really nice to chat with you. What's on your mind today — anything interesting going on in your week that you'd like to talk about in English?",
      openingFr:
          'Salut ! Ravi de discuter avec toi. Qu’est-ce qui te passe par la tête aujourd’hui — quelque chose d’intéressant dans ta semaine dont tu aimerais parler en anglais ?',
      followUpsEn: [
        "Tell me more about that! What made it stand out for you?",
        "That's really interesting — how did you feel about it?",
        "What's your next step or goal on that front?",
      ],
      starterHintsEn: [
        "Hey Amy! Today I want to talk about my daily routine and practise speaking more naturally.",
        "Hi! I'm preparing for my career goals and I'd love to discuss them in English.",
        "Honestly, I just want a casual conversation about books, learning, and technology.",
      ],
    ),
  ];

  static const List<LearnaLesson> lessons = [
    // ═══════════ A1 (DÉBUTANT) ═══════════
    LearnaLesson(
      id: 'a1_1',
      level: 'A1',
      unitNumber: 1,
      titleFr: 'Se présenter sans calques du français',
      subtitleFr: 'Âge, profession, accord (« To Be » vs « To Have »)',
      durationMin: 5,
      coreRules: [
        'En anglais, on utilise « To Be » (et jamais « have ») pour l’âge, la faim, la soif et le froid : "I am 24 years old", "I am hungry".',
        'On met toujours « a / an » devant un métier : "I am an engineer", "She is a student".',
        '« Agree » est un verbe direct : dites "I agree with you" (jamais "I am agree").',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'I have 24 years. ❌',
          natural: 'I am 24 years old. ✅',
          explanationFr: 'L’âge utilise toujours le verbe être (« am / is / are »).',
        ),
        CourseComparisonRow(
          avoid: 'I am agree with you. ❌',
          natural: 'I agree with you. ✅',
          explanationFr: '« Agree » est un verbe : pas besoin de « am » devant.',
        ),
        CourseComparisonRow(
          avoid: 'I am student in Dakar. ❌',
          natural: 'I am a student in Dakar. ✅',
          explanationFr: 'Ajoutez toujours « a / an » devant un statut ou métier au singulier.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: "Hi! I'm Amy. Nice to meet you! Where are you from?",
          french: 'Salut ! Je suis Amy. Ravie de te rencontrer ! D’où viens-tu ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: "Nice to meet you, Amy. I'm from Senegal and I'm a university student.",
          french: 'Ravi de te rencontrer, Amy. Je viens du Sénégal et je suis étudiant à l’université.',
        ),
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'That’s awesome! Are you excited to practise speaking English?',
          french: 'Génial ! Es-tu enthousiaste à l’idée de pratiquer l’anglais à l’oral ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'Yes, I agree that speaking every day is the fastest way to improve.',
          french: 'Oui, je suis d’accord que parler chaque jour est le moyen le plus rapide de progresser.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Comment dire naturellement « J’ai 23 ans » ?',
          options: ['I have 23 years.', 'I am 23 years old.', 'I am having 23.'],
          answer: 'I am 23 years old.',
          explanation: 'En anglais, l’âge se construit avec « to be ».',
        ),
        CourseQuizItem(
          question: 'Choisissez la phrase correcte :',
          options: ['I am agree with this idea.', 'I agree with this idea.', 'I agreeing this idea.'],
          answer: 'I agree with this idea.',
          explanation: '« Agree » est un verbe direct, sans « am ».',
        ),
      ],
      amyPracticeOpeningEn:
          "Let's practise introducing yourself naturally! Hi, I'm Amy — tell me your name, your age or background, and what you do!",
      amyPracticeIntroFr:
          'Mise en pratique de la leçon A1.1 : présentez-vous avec « I am... », votre métier/études et votre âge.',
    ),
    LearnaLesson(
      id: 'a1_2',
      level: 'A1',
      unitNumber: 2,
      titleFr: 'Parler de sa routine (Présent Simple)',
      subtitleFr: 'Le « -s » à he/she/it et les questions avec Do / Does',
      durationMin: 6,
      coreRules: [
        'À la 3e personne du singulier (he / she / it), ajoutez toujours -s ou -es : "She works", "He studies", "It goes".',
        'Pour poser une question ou faire une négation, utilisez DO / DOES + verbe nu : "Do you wake up early?", "He doesn’t drink coffee".',
        'Les adverbes de fréquence (always, usually, often, sometimes, never) se placent AVANT le verbe principal : "I usually read in the morning".',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'She work every morning. ❌',
          natural: 'She works every morning. ✅',
          explanationFr: 'Ne jamais oublier le -s avec he / she / it.',
        ),
        CourseComparisonRow(
          avoid: 'Does he works here? ❌',
          natural: 'Does he work here? ✅',
          explanationFr: '« Does » porte déjà le -s : le verbe principal reste à la forme de base.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'What time do you usually wake up on weekdays?',
          french: 'À quelle heure te réveilles-tu généralement en semaine ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'I usually wake up at six, and my brother wakes up at seven.',
          french: 'Je me réveille généralement à six heures, et mon frère se réveille à sept heures.',
        ),
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'Does your brother study English too?',
          french: 'Est-ce que ton frère étudie l’anglais aussi ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: "Yes! He listens to English podcasts, but he doesn't speak much yet.",
          french: 'Oui ! Il écoute des podcasts en anglais, mais il ne parle pas encore beaucoup.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Complétez : "_____ your sister live near the campus?"',
          options: ['Do', 'Does', 'Is'],
          answer: 'Does',
          explanation: '« Your sister » = she → auxiliaire « Does ».',
        ),
        CourseQuizItem(
          question: 'Quelle phrase est correcte ?',
          options: [
            'I wake up usually at 7.',
            'I usually wake up at 7.',
            'Usually I wakes up at 7.',
          ],
          answer: 'I usually wake up at 7.',
          explanation: '« Usually » se place juste avant le verbe principal.',
        ),
      ],
      amyPracticeOpeningEn:
          "Let's practise your daily routine! What time do you usually wake up, and what does a typical morning look like for you?",
      amyPracticeIntroFr:
          'Mise en pratique A1.2 : racontez votre routine avec « usually », « every morning » et le présent simple.',
    ),
    LearnaLesson(
      id: 'a1_3',
      level: 'A1',
      unitNumber: 3,
      titleFr: 'Commander & demander poliment',
      subtitleFr: '« Could I have... », « I would like... », « Excuse me »',
      durationMin: 5,
      coreRules: [
        'En anglais, « I want... » paraît brusque dans un café ou magasin : préférez "I’d like..." (I would like) ou "Could I have...?".',
        'Utilisez "Excuse me" pour attirer l’attention ou passer, et "Sorry" pour vous excuser.',
        'Ajoutez toujours "please" à la fin d’une demande : "A glass of water, please."',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'Give me a tea. ❌',
          natural: 'Could I have a cup of tea, please? ✅',
          explanationFr: '« Could I have...? » est poli, chaleureux et 100 % naturel.',
        ),
        CourseComparisonRow(
          avoid: 'I want to know where is the station. ❌',
          natural: 'Excuse me, could you tell me where the station is? ✅',
          explanationFr: 'Dans une question polie indirecte, le sujet passe avant le verbe ("where the station is").',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'Hi there! What can I get for you today?',
          french: 'Bonjour ! Que puis-je vous servir aujourd’hui ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: "Hello! Could I have a mint tea and a bottle of water, please?",
          french: 'Bonjour ! Pourrais-je avoir un thé à la menthe et une bouteille d’eau, s’il vous plaît ?',
        ),
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'Of course! Anything else to eat?',
          french: 'Bien sûr ! Autre chose à manger ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: "No, that's all for now, thank you very much.",
          french: 'Non, ce sera tout pour le moment, merci beaucoup.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'La façon la plus naturelle de commander un café :',
          options: [
            'I want one coffee now.',
            "I'd like a coffee, please.",
            'Give me one coffee.',
          ],
          answer: "I'd like a coffee, please.",
          explanation: '« I’d like... please » est la formule standard polie.',
        ),
        CourseQuizItem(
          question: 'Complétez : "Excuse me, could you tell me where _____?"',
          options: ['is the exit', 'the exit is', 'are the exit'],
          answer: 'the exit is',
          explanation: 'Après « could you tell me where », on garde l’ordre sujet + verbe.',
        ),
      ],
      amyPracticeOpeningEn:
          "Imagine we're at a café in London! Hi there — what would you like to order today, and do you need any directions afterwards?",
      amyPracticeIntroFr:
          'Mise en pratique A1.3 : commandez poliment avec « Could I have... » ou « I’d like... ».',
    ),

    // ═══════════ A2 (ÉLÉMENTAIRE) ═══════════
    LearnaLesson(
      id: 'a2_1',
      level: 'A2',
      unitNumber: 1,
      titleFr: 'Raconter au passé (Past Simple)',
      subtitleFr: 'Verbes réguliers, irréguliers et le piège « didn’t + base »',
      durationMin: 6,
      coreRules: [
        'Pour une action terminée et datée (yesterday, last week, in 2026), utilisez le Past Simple : "I worked", "I went", "I bought".',
        'Piège n°1 : après DID / DIDN’T, le verbe revient TOUJOURS à la forme de base : "I didn’t go" (jamais "didn’t went").',
        'Apprenez en priorité les irréguliers du quotidien : go→went, buy→bought, speak→spoke, take→took, write→wrote, think→thought.',
      ],
      traps: [
        CourseComparisonRow(
          avoid: "I didn't went to the meeting. ❌",
          natural: "I didn't go to the meeting. ✅",
          explanationFr: '« Didn’t » porte déjà la marque du passé.',
        ),
        CourseComparisonRow(
          avoid: 'Yesterday I buyed some fruit. ❌',
          natural: 'Yesterday I bought some fruit. ✅',
          explanationFr: '« Buy » est irrégulier : buy → bought → bought.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'Hey! What did you get up to last weekend?',
          french: 'Salut ! Qu’est-ce que tu as fait le week-end dernier ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'On Saturday I visited my family, and on Sunday I read a great book.',
          french: 'Samedi j’ai rendu visite à ma famille, et dimanche j’ai lu un super livre.',
        ),
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'Sounds relaxing! Did you go out in the evening?',
          french: 'Ça a l’air reposant ! Es-tu sorti le soir ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: "No, I didn't go out — I stayed home and got an early night.",
          french: 'Non, je ne suis pas sorti — je suis resté à la maison et je me suis couché tôt.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Complétez : "Yesterday, I _____ a really useful English book."',
          options: ['buyed', 'bought', 'have bought'],
          answer: 'bought',
          explanation: '« Yesterday » exige le Past Simple ; le passé de « buy » est « bought ».',
        ),
        CourseQuizItem(
          question: 'Complétez : "Sorry, I didn’t _____ your message earlier."',
          options: ['saw', 'seen', 'see'],
          answer: 'see',
          explanation: 'Après « didn’t », toujours la base verbale (« see »).',
        ),
      ],
      amyPracticeOpeningEn:
          "Let's practise talking about the past! Tell me about something memorable you did yesterday or last weekend — what happened?",
      amyPracticeIntroFr:
          'Mise en pratique A2.1 : racontez un souvenir récent au Past Simple.',
    ),
    LearnaLesson(
      id: 'a2_2',
      level: 'A2',
      unitNumber: 2,
      titleFr: 'Prépositions In / On / At & Make vs Do',
      subtitleFr: 'Les 2 règles qui éliminent 50 % des fautes courantes',
      durationMin: 6,
      coreRules: [
        'IN (large : mois, années, saisons, villes, moments) : in 2026, in Dakar, in the morning.',
        'ON (jours & dates précis) : on Monday, on July 4th, on the weekend.',
        'AT (heures exactes & lieux précis) : at 8:00 AM, at night, at work, at university.',
        'DO = tâches & devoirs (do homework, do research, do your best) • MAKE = créer/décider (make a decision, make progress, make a mistake).',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'The meeting is in Monday at the morning. ❌',
          natural: 'The meeting is on Monday in the morning. ✅',
          explanationFr: 'On + jour précis, in + moment de la journée.',
        ),
        CourseComparisonRow(
          avoid: 'I have to make my homework. ❌',
          natural: 'I have to do my homework. ✅',
          explanationFr: 'Les devoirs, tâches et recherches utilisent toujours « DO ».',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'When do you usually do your English practice?',
          french: 'Quand fais-tu généralement ta pratique d’anglais ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'Usually in the morning at seven, and on Saturdays I do extra speaking practice.',
          french: 'Généralement le matin à sept heures, et le samedi je fais de la pratique orale en plus.',
        ),
        CourseDialogueLine(
          speaker: 'Amy',
          english: "That's how you make real progress! Do you mind making small mistakes?",
          french: 'C’est comme ça qu’on fait de vrais progrès ! Est-ce que faire de petites erreurs te dérange ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: "Not anymore — making mistakes helps me remember the right phrase.",
          french: 'Plus maintenant — faire des erreurs m’aide à retenir la bonne tournure.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Complétez : "We need to _____ a clear decision _____ Friday."',
          options: ['do / in', 'make / on', 'make / at'],
          answer: 'make / on',
          explanation: '« Make a decision » + « on Friday » (jour de la semaine).',
        ),
        CourseQuizItem(
          question: 'Complétez : "My class starts _____ 9:00 AM _____ September."',
          options: ['at / in', 'on / in', 'at / on'],
          answer: 'at / in',
          explanation: '« At » pour une heure précise, « in » pour un mois.',
        ),
      ],
      amyPracticeOpeningEn:
          "Quick natural chat using time & Make/Do: What big decision or project are you planning this week, and when do you usually work on it?",
      amyPracticeIntroFr:
          'Mise en pratique A2.2 : utilisez « in / on / at » et « make / do » dans vos réponses.',
    ),
    LearnaLesson(
      id: 'a2_3',
      level: 'A2',
      unitNumber: 3,
      titleFr: 'Parler de ses projets futurs',
      subtitleFr: 'Choisir entre « Going to », « Will » et le présent continu',
      durationMin: 5,
      coreRules: [
        'GOING TO : intention ou projet déjà décidé ("I’m going to learn Python this summer").',
        'WILL : décision prise sur le moment, promesse ou prédiction ("Don’t worry, I’ll help you!", "It will be great").',
        'PRESENT CONTINUOUS : rendez-vous déjà fixé dans l’agenda ("I’m meeting my mentor tomorrow at 4 PM").',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'Tomorrow I will go to visit my aunt (déjà prévu). ❌',
          natural: "Tomorrow I'm going to visit my aunt. ✅",
          explanationFr: 'Pour un projet déjà planifié, « be going to » est beaucoup plus naturel que « will ».',
        ),
        CourseComparisonRow(
          avoid: 'I going to study tonight. ❌',
          natural: "I'm going to study tonight. ✅",
          explanationFr: 'N’oubliez jamais l’auxiliaire « am / is / are » avant « going to ».',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'What are you going to focus on over the next few months?',
          french: 'Sur quoi vas-tu te concentrer au cours des prochains mois ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: "I'm going to improve my spoken English and finish my main project.",
          french: 'Je vais améliorer mon anglais parlé et terminer mon projet principal.',
        ),
        CourseDialogueLine(
          speaker: 'Amy',
          english: "Brilliant! I'll help you practise whenever you're ready.",
          french: 'Génial ! Je t’aiderai à pratiquer dès que tu seras prêt.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Vous venez de voir un ami porter un sac lourd. Vous proposez votre aide sur le coup :',
          options: [
            "I'm going to carry that.",
            "Here, I'll carry that for you!",
            'I carrying that.',
          ],
          answer: "Here, I'll carry that for you!",
          explanation: 'Décision spontanée / offre d’aide → « will » (« I’ll »).',
        ),
        CourseQuizItem(
          question: 'Un projet déjà décidé depuis un mois :',
          options: [
            "I'm going to launch my app this year.",
            'I launch my app yesterday.',
            'I going to launch my app.',
          ],
          answer: "I'm going to launch my app this year.",
          explanation: 'Intention décidée à l’avance → « am/is/are going to ».',
        ),
      ],
      amyPracticeOpeningEn:
          "Tell me about your plans! What are you going to work on this week, and what goal are you excited about for the coming months?",
      amyPracticeIntroFr:
          'Mise en pratique A2.3 : exprimez vos projets futurs avec « I’m going to... » et « I’ll... ».',
    ),

    // ═══════════ B1 (INTERMÉDIAIRE) ═══════════
    LearnaLesson(
      id: 'b1_1',
      level: 'B1',
      unitNumber: 1,
      titleFr: 'Present Perfect vs Past & For / Since',
      subtitleFr: 'Relier le passé au présent sans confondre « for » et « since »',
      durationMin: 7,
      coreRules: [
        'Present Perfect (have/has + participe passé) décrit une durée toujours en cours ou un bilan : "I have lived here for 3 years" (j’y vis encore).',
        'FOR + une durée mesurée (for two hours, for three months, for five years).',
        'SINCE + un point de départ exact (since 2026, since Monday, since I was a child).',
        'Si le moment est fini et daté (yesterday, in 2022, two days ago) → Past Simple obligatoire ("I saw him yesterday", jamais "I have seen him yesterday").',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'I study English since 2 years. ❌',
          natural: 'I have studied English for 2 years. ✅',
          explanationFr: 'Action commencée dans le passé et toujours vraie → Present Perfect + FOR (durée).',
        ),
        CourseComparisonRow(
          avoid: 'I have finished the report yesterday. ❌',
          natural: 'I finished the report yesterday. ✅',
          explanationFr: '« Yesterday » est un passé révolu → Past Simple.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'How long have you been working in your current field?',
          french: 'Depuis combien de temps travailles-tu dans ton domaine actuel ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: "I've been studying it for three years, and I've practised English every day since January.",
          french: 'Je l’étudie depuis trois ans, et je pratique l’anglais tous les jours depuis janvier.',
        ),
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'Have you noticed a real difference in your confidence?',
          french: 'As-tu remarqué une vraie différence dans ta confiance ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'Definitely! Last month I even gave a short presentation in English.',
          french: 'Carrément ! Le mois dernier j’ai même fait une courte présentation en anglais.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Complétez : "I have worked on this app _____ five hours."',
          options: ['since', 'for', 'during'],
          answer: 'for',
          explanation: '« Five hours » est une durée → « for ».',
        ),
        CourseQuizItem(
          question: 'Complétez : "She has lived in Saint-Louis _____ 2022."',
          options: ['for', 'since', 'from'],
          answer: 'since',
          explanation: '« 2022 » est un point de départ précis → « since ».',
        ),
      ],
      amyPracticeOpeningEn:
          "Let's practise Present Perfect naturally! How long have you been learning English, and what have you achieved recently that made you feel proud?",
      amyPracticeIntroFr:
          'Mise en pratique B1.1 : utilisez « I have ... for / since » et le Past Simple pour les dates précises.',
    ),
    LearnaLesson(
      id: 'b1_2',
      level: 'B1',
      unitNumber: 2,
      titleFr: 'Éliminer les faux amis FR → EN',
      subtitleFr: 'Actually, Currently, Attend, Sensible, Library, Delay',
      durationMin: 6,
      coreRules: [
        'Actually = en fait / à vrai dire • Currently = actuellement (en ce moment).',
        'Attend = assister à / participer (attend a meeting) • Wait for = attendre.',
        'Sensible = raisonnable / censé • Sensitive = sensible.',
        'Library = bibliothèque • Bookshop = librairie • Deadline = date limite (delay = retard).',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'Actually, I am looking for an internship. ❌',
          natural: 'Currently, I am looking for an internship. ✅',
          explanationFr: 'Pour dire « actuellement », utilisez toujours « currently » ou « right now ».',
        ),
        CourseComparisonRow(
          avoid: 'We must respect the delay of Friday. ❌',
          natural: 'We must meet the Friday deadline. ✅',
          explanationFr: '« Delay » signifie retard ; un délai / échéance = « deadline ».',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'What are you currently focusing on this semester?',
          french: 'Sur quoi te concentres-tu actuellement ce semestre ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: "Currently I'm preparing for my exams, and I attend two workshops a week.",
          french: 'Actuellement je prépare mes examens, et j’assiste à deux ateliers par semaine.',
        ),
        CourseDialogueLine(
          speaker: 'Amy',
          english: "That sounds like a sensible schedule! Do you study at the library?",
          french: 'Ça a l’air d’un emploi du temps raisonnable ! Est-ce que tu étudies à la bibliothèque ?',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Comment traduire « Actuellement, je travaille sur un projet mobile » ?',
          options: [
            'Actually, I work on a mobile project.',
            'Currently, I am working on a mobile project.',
            'Eventually, I work on a mobile project.',
          ],
          answer: 'Currently, I am working on a mobile project.',
          explanation: '« Currently » = actuellement ; « actually » = en fait.',
        ),
        CourseQuizItem(
          question: 'Que signifie « She attended the conference » ?',
          options: [
            'Elle a attendu la conférence.',
            'Elle a assisté à la conférence.',
            'Elle a annulé la conférence.',
          ],
          answer: 'Elle a assisté à la conférence.',
          explanation: '« Attend » = assister à (jamais attendre).',
        ),
      ],
      amyPracticeOpeningEn:
          "Tell me — what are you currently working on these days, and did you attend any interesting talks, classes, or meetings recently?",
      amyPracticeIntroFr:
          'Mise en pratique B1.2 : employez « currently », « actually », « attend » et « deadline » sans faux amis.',
    ),
    LearnaLesson(
      id: 'b1_3',
      level: 'B1',
      unitNumber: 3,
      titleFr: 'Nuancer son opinion (Although vs Despite)',
      subtitleFr: 'Relier des idées opposées avec fluidité',
      durationMin: 6,
      coreRules: [
        'ALTHOUGH / EVEN THOUGH + Sujet + Verbe : "Although it was difficult, she stayed calm."',
        'DESPITE / IN SPITE OF + Nom ou Verbe-ing (JAMAIS "despite of" !) : "Despite the difficulty...", "Despite feeling tired...".',
        'Connecteurs de transition naturels à l’oral : "However...", "On the other hand...", "Even so...".',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'Despite of the rain, we went out. ❌',
          natural: 'Despite the rain, we went out. ✅',
          explanationFr: '« Despite » ne prend jamais « of ».',
        ),
        CourseComparisonRow(
          avoid: 'Although the noise, I focused. ❌',
          natural: 'Although it was noisy, I focused. ✅',
          explanationFr: '« Although » doit être suivi d’un sujet et d’un verbe.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'Do you find it easy to stay consistent with English every day?',
          french: 'Trouves-tu facile de rester régulier en anglais chaque jour ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'Although my schedule is tight, I still find fifteen minutes despite feeling tired.',
          french: 'Bien que mon emploi du temps soit serré, je trouve quand même quinze minutes malgré la fatigue.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Complétez : "_____ the tight deadline, the team delivered on time."',
          options: ['Although', 'Despite', 'Despite of'],
          answer: 'Despite',
          explanation: 'Devant un groupe nominal (« the tight deadline »), utilisez « Despite ».',
        ),
        CourseQuizItem(
          question: 'Complétez : "_____ she was nervous, her speech was remarkably clear."',
          options: ['Despite', 'Although', 'In spite'],
          answer: 'Although',
          explanation: 'Devant « sujet + verbe » (« she was nervous ») → « Although ».',
        ),
      ],
      amyPracticeOpeningEn:
          "Let's practise expressing nuance! What is one habit or skill you're building right now despite having a busy schedule?",
      amyPracticeIntroFr:
          'Mise en pratique B1.3 : construisez une réponse nuancée avec « although », « despite » ou « however ».',
    ),

    // ═══════════ B2 (AVANCÉ) ═══════════
    LearnaLesson(
      id: 'b2_1',
      level: 'B2',
      unitNumber: 1,
      titleFr: 'Conditionnels 1, 2 et 3 sans hésiter',
      subtitleFr: 'Exprimer des hypothèses réelles, imaginaires ou passées',
      durationMin: 7,
      coreRules: [
        '1er (réel) : If + Present, WILL + base → "If we test early, we will catch bugs."',
        '2e (imaginaire/présent) : If + Past, WOULD + base → "If I had more time, I would travel." (Jamais "If I would have").',
        '3e (regret/passé) : If + had + V3, WOULD HAVE + V3 → "If we had checked the battery, we would have avoided the outage."',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'If I would have more time, I would read more. ❌',
          natural: 'If I had more time, I would read more. ✅',
          explanationFr: 'Pas de « would » dans la clause en « If ».',
        ),
        CourseComparisonRow(
          avoid: 'If we checked earlier, we would have seen it. ❌',
          natural: 'If we had checked earlier, we would have seen it. ✅',
          explanationFr: 'Au 3e conditionnel : « had + participe passé » dans la condition.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'If you could spend six months working anywhere in the world, where would you go?',
          french: 'Si tu pouvais passer six mois à travailler n’importe où dans le monde, où irais-tu ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'If I had the chance, I would spend six months in London to sharpen my English and network.',
          french: 'Si j’en avais l’occasion, je passerais six mois à Londres pour perfectionner mon anglais et élargir mon réseau.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Complétez : "If we had verified the numbers, we _____ avoided that error."',
          options: ['would', 'will have', 'would have'],
          answer: 'would have',
          explanation: '3e conditionnel : If + had + V3 → would have + V3.',
        ),
        CourseQuizItem(
          question: 'Quelle phrase est correcte ?',
          options: [
            'If I would know the answer, I would tell you.',
            'If I knew the answer, I would tell you.',
            'If I know the answer, I would tell you.',
          ],
          answer: 'If I knew the answer, I would tell you.',
          explanation: '2e conditionnel : If + Past Simple (« knew »), would + base.',
        ),
      ],
      amyPracticeOpeningEn:
          "Hypothetical question for you! If you could design your ideal workday or launch any project without budget limits, what would you build?",
      amyPracticeIntroFr:
          'Mise en pratique B2.1 : répondez avec le 2e ou 3e conditionnel (« If I had..., I would... »).',
    ),
    LearnaLesson(
      id: 'b2_2',
      level: 'B2',
      unitNumber: 2,
      titleFr: 'Phrasal Verbs indispensables au travail',
      subtitleFr: 'Figure out, Look into, Carry out, Follow up, Come up with',
      durationMin: 6,
      coreRules: [
        'figure out = comprendre / trouver la solution • come up with = proposer une idée.',
        'look into = examiner en détail / enquêter • carry out = mener à bien / exécuter.',
        'follow up = faire le suivi • put off = reporter • break down = décomposer (ou tomber en panne).',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'We discussed about the issue. ❌',
          natural: 'We discussed the issue and looked into the root cause. ✅',
          explanationFr: '« Discuss » est transitif direct (sans « about ») ; « look into » ajoute une vraie fluidité native.',
        ),
        CourseComparisonRow(
          avoid: 'Can you explain me how it works? ❌',
          natural: 'Can you explain to me how to figure this out? ✅',
          explanationFr: 'Structure obligatoire : explain + to someone (ou explain something to someone).',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'How did your team handle that unexpected issue yesterday?',
          french: 'Comment votre équipe a-t-elle géré cet imprévu hier ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'We looked into the logs, figured out the cause, and came up with a clean fix before lunch.',
          french: 'Nous avons examiné les journaux, trouvé la cause et élaboré un correctif propre avant le déjeuner.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Quel phrasal verb signifie « proposer une nouvelle idée / solution » ?',
          options: ['put off', 'come up with', 'give up'],
          answer: 'come up with',
          explanation: '« Come up with a solution » = trouver / proposer une solution.',
        ),
        CourseQuizItem(
          question: 'Quel phrasal verb signifie « examiner en détail » ?',
          options: ['look into', 'run out of', 'turn down'],
          answer: 'look into',
          explanation: '« Look into a problem » = examiner un problème en profondeur.',
        ),
      ],
      amyPracticeOpeningEn:
          "Tell me about a time you had to figure out a tricky problem — what did you look into, and what solution did you come up with?",
      amyPracticeIntroFr:
          'Mise en pratique B2.2 : intégrez au moins 2 phrasal verbs (figure out, look into, come up with, follow up).',
    ),
    LearnaLesson(
      id: 'b2_3',
      level: 'B2',
      unitNumber: 3,
      titleFr: 'Réussir un entretien & pitcher un projet (STAR)',
      subtitleFr: 'Situation · Task · Action · Result en anglais professionnel',
      durationMin: 7,
      coreRules: [
        'Structure STAR en 60–90s : S (Contexte bref) → T (Votre mission) → A (Verbes d’action concrets : led, designed, streamlined) → R (Résultat chiffré).',
        'Évitez le vague « I helped with... » : utilisez « I spearheaded... », « I coordinated... », « I reduced latency by 35% ».',
        'Terminez par la leçon apprise ou l’impact durable pour l’équipe.',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'We made a big project and it was very good. ❌',
          natural: 'I coordinated a cross-functional project that cut delivery time by 25%. ✅',
          explanationFr: 'Un verbe précis + un chiffre concret multiplient la crédibilité en entretien.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'Could you share a concrete example of a project where you made a measurable impact?',
          french: 'Pouvez-vous partager un exemple concret de projet où vous avez eu un impact mesurable ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'In my previous role, our onboarding process was slow. I automated the checklist, which cut setup time in half.',
          french: 'Dans mon poste précédent, l’intégration était lente. J’ai automatisé la liste de contrôle, ce qui a réduit le temps de moitié.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Quelle formulation STAR a le plus d’impact en entretien ?',
          options: [
            'I did some work on the database.',
            'I redesigned the database queries, reducing load time by 40%.',
            'The database was better after.',
          ],
          answer: 'I redesigned the database queries, reducing load time by 40%.',
          explanation: 'Verbe d’action précis + résultat mesurable.',
        ),
      ],
      amyPracticeOpeningEn:
          "Let's run a quick real interview! Tell me about a challenge you faced on a project using the STAR structure — what was the situation, what action did you take, and what was the result?",
      amyPracticeIntroFr:
          'Mise en pratique B2.3 : répondez en suivant Situation → Action → Résultat chiffré.',
    ),

    // ═══════════ C1 (AUTONOME) ═══════════
    LearnaLesson(
      id: 'c1_1',
      level: 'C1',
      unitNumber: 1,
      titleFr: 'Style soutenu, inversions & emphase',
      subtitleFr: '« Not only did we... », « Had we known... », « Rarely have I... »',
      durationMin: 7,
      coreRules: [
        'Quand un adverbe restrictif ou négatif ouvre la phrase, on inverse auxiliaire + sujet : "Not only did we cut costs, we also improved quality."',
        'Conditionnel 3 élégant sans "if" : "Had we tested earlier, we would have spotted the flaw."',
        'Mise en relief naturelle (cleft sentences) : "What matters most is consistency", "It was teamwork that made the difference."',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'Not only we saved time, but also money. ❌',
          natural: 'Not only did we save time, but we also reduced costs. ✅',
          explanationFr: '« Not only » en tête impose l’inversion « did + sujet + base ».',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'What turned that difficult launch into a success in the end?',
          french: 'Qu’est-ce qui a finalement transformé ce lancement difficile en succès ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'Not only did we listen closely to users, but we also simplified the interface — had we ignored their feedback, adoption would have stalled.',
          french: 'Non seulement nous avons écouté les utilisateurs, mais nous avons aussi simplifié l’interface — si nous avions ignoré leurs retours, l’adoption aurait stagné.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Complétez : "Not only _____ the deadline, but we also exceeded expectations."',
          options: ['we met', 'did we meet', 'we did meet'],
          answer: 'did we meet',
          explanation: 'Inversion obligatoire après « Not only » en début de phrase.',
        ),
      ],
      amyPracticeOpeningEn:
          "Let's elevate your style to C1! Tell me about a lesson you learned the hard way — try using 'Not only did...' or 'What matters most is...'",
      amyPracticeIntroFr:
          'Mise en pratique C1.1 : utilisez une inversion ou une mise en relief (« What matters most is... »).',
    ),
    LearnaLesson(
      id: 'c1_2',
      level: 'C1',
      unitNumber: 2,
      titleFr: 'Argumenter & répondre aux objections',
      subtitleFr: 'Granted, Provided that, That being said, On balance',
      durationMin: 7,
      coreRules: [
        'Concéder intelligemment avant de contre-argumenter : "Granted, speed matters; however, accuracy comes first."',
        'Poser une condition précise : "Provided that learners verify sources, AI accelerates mastery."',
        'Conclure avec hauteur : "On balance, the benefits outweigh the risks."',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'You are wrong because... ❌',
          natural: "That's a fair point; that being said, I see one major risk... ✅",
          explanationFr: 'En anglais C1, la concession diplomatique rend l’argumentation beaucoup plus persuasive.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'Some argue remote work weakens team culture. Where do you stand?',
          french: 'Certains affirment que le télétravail affaiblit la culture d’équipe. Quelle est ta position ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: "Granted, spontaneous chats are rarer; that being said, remote work thrives provided that communication stays intentional.",
          french: 'Certes, les discussions spontanées sont plus rares ; cela dit, le télétravail fonctionne très bien à condition que la communication reste intentionnelle.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Quelle expression signifie « à condition que » dans un registre soutenu ?',
          options: ['Provided that', 'Despite of', 'Whereas'],
          answer: 'Provided that',
          explanation: '« Provided that » = à condition que.',
        ),
      ],
      amyPracticeOpeningEn:
          "Let's debate at C1 level: Does working remotely help or hurt young professionals starting their careers? Give me a balanced take!",
      amyPracticeIntroFr:
          'Mise en pratique C1.2 : argumentez avec « Granted... », « That being said... » ou « Provided that... ».',
    ),
    LearnaLesson(
      id: 'c1_3',
      level: 'C1',
      unitNumber: 3,
      titleFr: 'Indénombrables & collocations professionnelles',
      subtitleFr: 'Information, Advice, Research, Equipment, Feedback',
      durationMin: 6,
      coreRules: [
        'Toujours au SINGULIER (jamais de -s, jamais « an ») : information, advice, research, equipment, feedback, progress, evidence.',
        'Pour compter : "a piece of advice", "some useful feedback", "a great deal of research".',
        'Collocations clés : "draw a conclusion", "bridge the gap", "raise awareness", "strike a balance".',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'Thanks for these useful advices and informations. ❌',
          natural: 'Thanks for this useful advice and information. ✅',
          explanationFr: '« Advice » et « information » sont invariables en anglais.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'What kind of feedback helped you improve the fastest?',
          french: 'Quel type de retour t’a aidé à progresser le plus vite ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'Honest, specific feedback — and a great piece of advice a mentor gave me about striking a balance between speed and clarity.',
          french: 'Des retours honnêtes et précis — et un excellent conseil d’un mentor sur l’équilibre entre rapidité et clarté.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Choisissez la phrase 100 % exacte :',
          options: [
            'We collected many informations.',
            'We collected a great deal of information.',
            'We collected an information.',
          ],
          answer: 'We collected a great deal of information.',
          explanation: '« Information » est indénombrable.',
        ),
      ],
      amyPracticeOpeningEn:
          "What's the best piece of advice or honest feedback you've ever received, and how did it change the way you work?",
      amyPracticeIntroFr:
          'Mise en pratique C1.3 : utilisez « a piece of advice », « feedback », « progress » ou « strike a balance ».',
    ),

    // ═══════════ C2 (MAÎTRISE) ═══════════
    LearnaLesson(
      id: 'c2_1',
      level: 'C2',
      unitNumber: 1,
      titleFr: 'Expressions idiomatiques & nuances UK / US',
      subtitleFr: 'Parler avec aisance et naturel dans tout contexte',
      durationMin: 7,
      coreRules: [
        'Idiomes pro élégants : "cut to the chase" (aller à l’essentiel), "the bottom line" (l’essentiel), "on the same page" (sur la même longueur d’onde).',
        'Nuances UK vs US : "quite good" (UK = plutôt bien / réservé, US = vraiment bien), "fortnight" (UK = 2 semaines), "schedule" (/ˈʃedjuːl/ UK vs /ˈskedʒuːl/ US).',
        'Sous-entendu diplomatique britannique : "With respect..." / "I’m not entirely convinced..." = désaccord ferme mais courtois.',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'Let us go directly to the main point now. ❌',
          natural: "Let's cut to the chase and align on the bottom line. ✅",
          explanationFr: 'Plus concis, idiomatique et percutant au niveau C2.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: "Before we wrap up, let's make sure we're on the same page about next quarter.",
          french: 'Avant de conclure, assurons-nous d’être sur la même longueur d’onde pour le trimestre prochain.',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'Absolutely. The bottom line is that quality takes precedence over rushing features out.',
          french: 'Tout à fait. L’essentiel est que la qualité passe avant la précipitation.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Que signifie « to cut to the chase » ?',
          options: [
            'Annuler une réunion',
            'Aller droit à l’essentiel',
            'Courir après un objectif',
          ],
          answer: 'Aller droit à l’essentiel',
          explanation: 'Idiome incontournable en anglais courant et professionnel.',
        ),
      ],
      amyPracticeOpeningEn:
          "Let's chat at C2 fluency! If you had to cut to the chase, what really separates someone who speaks good English from someone who commands a room?",
      amyPracticeIntroFr:
          'Mise en pratique C2.1 : utilisez des expressions idiomatiques naturelles (« cut to the chase », « the bottom line »).',
    ),
    LearnaLesson(
      id: 'c2_2',
      level: 'C2',
      unitNumber: 2,
      titleFr: 'Rhétorique, précision & concision orale',
      subtitleFr: 'Éliminer les mots parasites et structurer un propos marquant',
      durationMin: 7,
      coreRules: [
        'Remplacez les formulations lourdes ("due to the fact that" → "because", "in order to" → "to", "a large number of" → "many").',
        'Utilisez la règle de trois à l’oral : "clarity, consistency, and courage."',
        'Articulez une concession fine avec « albeit » ou « notwithstanding » : "a modest step, albeit a decisive one."',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'Due to the fact that there are many things to consider... ❌',
          natural: 'Because several competing priorities are at stake... ✅',
          explanationFr: 'La maîtrise C2 privilégie la densité et la clarté plutôt que la longueur.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'How would you summarize your philosophy of lifelong learning in one sharp sentence?',
          french: 'Comment résumerais-tu ta philosophie de l’apprentissage continu en une phrase forte ?',
        ),
        CourseDialogueLine(
          speaker: 'You',
          english: 'True mastery is rarely sudden; it is the compound interest of daily curiosity, discipline, and humility.',
          french: 'La vraie maîtrise est rarement soudaine ; c’est l’intérêt composé de la curiosité, de la discipline et de l’humilité quotidiennes.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Quelle tournure est la plus concise et élégante ?',
          options: [
            'It was a slow process, albeit a deeply rewarding one.',
            'It was a slow process due to the fact that it took time, and also rewarding.',
            'It was slow but very much rewarding in a way.',
          ],
          answer: 'It was a slow process, albeit a deeply rewarding one.',
          explanation: '« Albeit » condense élégamment une concession.',
        ),
      ],
      amyPracticeOpeningEn:
          "C2 rhetorical challenge: summarize in two crisp, memorable sentences what makes a community thrive over the long term!",
      amyPracticeIntroFr:
          'Mise en pratique C2.2 : exprimez une idée profonde avec concision, rythme et précision.',
    ),
    LearnaLesson(
      id: 'c2_3',
      level: 'C2',
      unitNumber: 3,
      titleFr: 'Prononciation fine : TH, H expiré, -ED & accent tonique',
      subtitleFr: 'Gagner une diction limpide comprise partout dans le monde',
      durationMin: 6,
      coreRules: [
        'Son TH : pointe de la langue légèrement entre les dents — sourd /θ/ (think, three, thorough) et sonore /ð/ (this, although, smooth).',
        'Terminaison -ED : /ɪd/ après t/d (decided, wanted) • /t/ après p/k/f/s/sh/ch (worked, watched) • /d/ ailleurs (learned, lived).',
        'Accent tonique (Word Stress) : un même mot change de sens selon la syllabe accentuée — PRO-ject (nom) vs pro-JECT (verbe), PRE-sent (nom) vs pre-SENT (verbe).',
      ],
      traps: [
        CourseComparisonRow(
          avoid: 'Prononcer "worked" comme "wor-ked" (2 syllabes). ❌',
          natural: 'Prononcer "worked" en 1 syllabe nette : /wɜːrkt/. ✅',
          explanationFr: 'On ne prononce « -ed » en syllabe séparée (/ɪd/) qu’après T ou D.',
        ),
      ],
      dialogue: [
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'Although three thoughtful thinkers worked through the afternoon, they remained thoroughly focused.',
          french: 'Phrase d’entraînement TH + -ED (répétez après Amy en mode lent puis fluide).',
        ),
        CourseDialogueLine(
          speaker: 'Amy',
          english: 'We must de-VE-lop a clear PRO-ject and pre-SENT our re-SULTS with honest confidence.',
          french: 'Phrase d’entraînement accent tonique + H aspiré.',
        ),
      ],
      quiz: [
        CourseQuizItem(
          question: 'Dans quel verbe la terminaison « -ed » se prononce-t-elle /ɪd/ (syllabe en plus) ?',
          options: ['worked', 'played', 'decided'],
          answer: 'decided',
          explanation: '« Decide » se termine par le son /d/ → « de-ci-ded » (/ɪd/).',
        ),
      ],
      amyPracticeOpeningEn:
          "Pronunciation coaching time! Read this aloud or type how you feel about English sounds: 'Although three thoughtful thinkers worked hard, they decided to stay thoroughly focused.' Which sound feels trickiest for you?",
      amyPracticeIntroFr:
          'Mise en pratique C2.3 : entraînez votre prononciation et votre rythme avec Amy.',
    ),
  ];

  static List<LearnaLesson> lessonsForLevel(String level) =>
      lessons.where((l) => l.level == level.toUpperCase()).toList();
}
