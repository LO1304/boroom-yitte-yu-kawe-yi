-- ============================================================================
-- Seed Data for BOROOM YITTÉ YU KAWÉ YI
-- Contains ONLY verified educational, linguistic & canonical dhikr references.
-- ============================================================================

-- 1. Daily Vocabulary (5 words per day, UK & US IPA, CEFR A2-C1)
INSERT INTO vocabulary (
  id, word, phonetic_uk, phonetic_us, part_of_speech, cefr_level,
  definition_en, definition_fr, example_sentence_en, example_sentence_fr, scheduled_date
) VALUES
  (
    '11111111-1111-4111-8111-000000000001',
    'Discernment',
    '/dɪˈsɜːn.mənt/',
    '/dɪˈsɝːn.mənt/',
    'noun',
    'C1',
    'The ability to judge well and distinguish subtle truths with clarity.',
    'La capacité de juger avec justesse et de distinguer la vérité avec finesse.',
    'Intellectual discernment prevents us from accepting claims without evidence.',
    'Le discernement intellectuel nous évite d''accepter des affirmations sans preuve.',
    CURRENT_DATE
  ),
  (
    '11111111-1111-4111-8111-000000000002',
    'Steadfast',
    '/ˈsted.fɑːst/',
    '/ˈsted.fæst/',
    'adjective',
    'B2',
    'Resolutely or dutifully firm and unwavering in purpose.',
    'Ferme, résolu et constant dans ses principes et son engagement.',
    'She remained steadfast in her daily study routine despite a busy schedule.',
    'Elle est restée constante dans sa routine d''étude quotidienne malgré un emploi du temps chargé.',
    CURRENT_DATE
  ),
  (
    '11111111-1111-4111-8111-000000000003',
    'Coherence',
    '/kəʊˈhɪə.rəns/',
    '/koʊˈhɪr.əns/',
    'noun',
    'B2',
    'The quality of being logical, consistent, and forming a unified whole.',
    'La qualité d''un discours logique, structuré et cohérent.',
    'Your argument gained strength from the coherence between your premises and examples.',
    'Votre argument a gagné en force grâce à la cohérence entre vos prémisses et vos exemples.',
    CURRENT_DATE
  ),
  (
    '11111111-1111-4111-8111-000000000004',
    'Articulate',
    '/ɑːˈtɪk.jə.lət/',
    '/ɑːrˈtɪk.jə.lət/',
    'adjective',
    'B1',
    'Able to express thoughts and ideas clearly and effectively in speech or writing.',
    'Capable d''exprimer ses idées avec clarté et précision à l''oral comme à l''écrit.',
    'Practice helps every learner become a more articulate speaker.',
    'La pratique aide chaque apprenant à devenir un orateur plus clair.',
    CURRENT_DATE
  ),
  (
    '11111111-1111-4111-8111-000000000005',
    'Stewardship',
    '/ˈstjuː.əd.ʃɪp/',
    '/ˈstuː.ɚd.ʃɪp/',
    'noun',
    'C1',
    'The responsible and ethical care of resources entrusted to one''s trust.',
    'La gestion responsable, éthique et fidèle d''un dépôt ou d''une ressource confiée.',
    'Community stewardship means protecting shared knowledge for future generations.',
    'La responsabilité communautaire consiste à préserver le savoir partagé pour les générations futures.',
    CURRENT_DATE
  )
ON CONFLICT (id) DO NOTHING;

-- 2. English Club Lessons (Modules A-J)
INSERT INTO english_lessons (
  id, module_type, title, description, cefr_level, english_variant, content_markdown, order_index, is_weekly_challenge
) VALUES
  (
    '22222222-2222-4222-8222-000000000001',
    'grammar',
    'Structuring Nuanced Arguments with Concession Clauses',
    'Master although, even though, whereas, and despite to express balanced reasoning in debates.',
    'B2',
    'en-GB',
    E'### Key Structures\n- **Although / Even though + Subject + Verb**: *Although technology accelerates access to information, it requires critical filtering.*\n- **Despite / In spite of + Noun / -ing**: *Despite rapid innovation, ethical frameworks remain essential.*\n- **Whereas**: Contrast two balanced perspectives clearly.',
    1,
    FALSE
  ),
  (
    '22222222-2222-4222-8222-000000000002',
    'pronunciation_lab',
    'Clarity Over Accent: Word Stress & Connected Speech',
    'Focus on syllable stress and clear consonant articulation for international intelligibility.',
    'B1',
    'en-US',
    E'### Intelligibility Principles\nYour natural accent is respected. Focus on **primary word stress** (e.g., *de-VE-lop-ment*, *phi-LO-so-phy*, *e-VA-lu-ate*) and clear pauses between idea groups so listeners follow effortlessly.',
    2,
    FALSE
  ),
  (
    '22222222-2222-4222-8222-000000000003',
    'listening',
    'Understanding Academic & Ethical Discussions',
    'Active listening strategies for identifying thesis, supporting evidence, and counterarguments.',
    'B2',
    'en-GB',
    E'### Listening Checklist\n1. Identify the speaker''s main thesis in the opening 20 seconds.\n2. Track signpost words (*firstly*, *however*, *for instance*, *consequently*).\n3. Distinguish empirical facts from personal opinions.',
    3,
    FALSE
  ),
  (
    '22222222-2222-4222-8222-000000000004',
    'weekly_speaking_challenge',
    'Weekly Speaking Challenge: Ethics of AI in Education',
    'Deliver a 90-second structured reflection balancing opportunity and human responsibility.',
    'B2',
    'en-GB',
    E'### Prompt\n*How can young learners use AI tools to deepen understanding rather than replace genuine effort?*\nInclude one concrete example and one boundary you consider essential.',
    4,
    TRUE
  )
ON CONFLICT (id) DO NOTHING;

-- 3. English Exercises
INSERT INTO english_exercises (
  id, lesson_id, exercise_type, prompt, options, correct_answer, explanation, cefr_level
) VALUES
  (
    '33333333-3333-4333-8333-000000000001',
    '22222222-2222-4222-8222-000000000001',
    'grammar_quiz',
    'Choose the grammatically accurate sentence:',
    '["Despite he studied late, he felt prepared.", "Although he studied late, he felt prepared.", "Even though of the delay, the session began.", "Whereas studying late, he felt prepared."]'::jsonb,
    'Although he studied late, he felt prepared.',
    '"Although" introduces a full clause (subject + verb), whereas "despite" takes a noun phrase or -ing form.',
    'B2'
  ),
  (
    '33333333-3333-4333-8333-000000000002',
    '22222222-2222-4222-8222-000000000001',
    'grammar_quiz',
    'Complete the sentence: "_____ the complexity of the question, the team stayed calm."',
    '["Although", "Despite", "Even though", "Whereas"]'::jsonb,
    'Despite',
    '"The complexity of the question" is a noun phrase, so "Despite" is required.',
    'B2'
  )
ON CONFLICT (id) DO NOTHING;

-- 4. Quiz Arena Questions (Verified Educational & Reasoning Bank)
INSERT INTO quiz_questions (
  id, category, question_type, difficulty, question_text, options, correct_option_index, explanation, verified_references, time_limit_seconds, points, language
) VALUES
  (
    '44444444-4444-4444-8444-000000000001',
    'logic',
    'logic_puzzle',
    'intermediate',
    'Si tous les chercheurs rigoureux vérifient leurs sources, et que certains étudiants sont des chercheurs rigoureux, quelle conclusion est logiquement certaine ?',
    '["Tous les étudiants vérifient leurs sources", "Certains étudiants vérifient leurs sources", "Aucun étudiant ne fait d''erreur", "Tous ceux qui vérifient leurs sources sont étudiants"]'::jsonb,
    1,
    'Par syllogisme valide (Darii) : si certains A sont B et tous les B sont C, alors certains A sont nécessairement C.',
    '["Logique formelle aristotélicienne — syllogisme Darii"]'::jsonb,
    25,
    100,
    'fr'
  ),
  (
    '44444444-4444-4444-8444-000000000002',
    'islamic_thought',
    'islamic_knowledge',
    'beginner',
    'Quel terme désigne, dans la méthodologie scientifique islamique classique, l''examen critique de la chaîne de transmission d''un récit ?',
    '["Al-Isnad", "Al-Qiyas", "Al-Ijma", "Al-Istihsan"]'::jsonb,
    0,
    'Al-Isnad désigne la chaîne des transmetteurs permettant de vérifier l''authenticité et la continuité d''une narration.',
    '["Sciences du Hadith (Ulum al-Hadith) — Ibn al-Salah"]'::jsonb,
    25,
    100,
    'fr'
  ),
  (
    '44444444-4444-4444-8444-000000000003',
    'science',
    'mcq',
    'intermediate',
    'Pourquoi une corrélation statistique entre deux variables ne prouve-t-elle pas à elle seule une causalité ?',
    '["Parce que les moyennes sont toujours fausses", "En raison d''une possible variable confondante ou d''une causalité inverse", "Parce que les mathématiques ne s''appliquent pas au réel", "Parce que toute corrélation est due au hasard"]'::jsonb,
    1,
    'Une troisième variable confondante, une coïncidence ou une inversion cause-effet peuvent produire une corrélation sans lien causal direct.',
    '["Méthodologie scientifique & statistique inférentielle"]'::jsonb,
    25,
    120,
    'fr'
  ),
  (
    '44444444-4444-4444-8444-000000000004',
    'philosophy',
    'philosophical_reasoning',
    'advanced',
    'Dans l''éthique de la discussion, que signifie le principe de charité interprétative ?',
    '["Être toujours d''accord avec son interlocuteur", "Reconstruire l''argument de l''autre dans sa forme la plus cohérente avant de le critiquer", "Ignorer les contradictions d''un texte", "Éviter tout débat sur les valeurs"]'::jsonb,
    1,
    'Le principe de charité (Donald Davidson / tradition analytique) consiste à interpréter l''argument adverse sous son meilleur jour logique afin d''éviter l''homme de paille.',
    '["Donald Davidson, Inquiries into Truth and Interpretation"]'::jsonb,
    30,
    150,
    'fr'
  ),
  (
    '44444444-4444-4444-8444-000000000005',
    'history',
    'history',
    'intermediate',
    'Quelle institution fondée à Bagdad au IXe siècle joua un rôle majeur dans la traduction et l''essor scientifique pluridisciplinaire ?',
    '["Bayt al-Hikma (La Maison de la Sagesse)", "L''Université de Bologne", "La Royal Society", "L''Académie de Platon"]'::jsonb,
    0,
    'Bayt al-Hikma, soutenue sous al-Ma''mun au IXe siècle, rassembla des savants de multiples horizons pour traduire, commenter et développer mathématiques, astronomie, médecine et philosophie.',
    '["Histoire des sciences — Roshdi Rashed"]'::jsonb,
    25,
    100,
    'fr'
  )
ON CONFLICT (id) DO NOTHING;

-- 5. YITTÉ ZIKR — Saturday 20:00 GMT Recurring Session (Verified Canonical References)
INSERT INTO zikr_sessions (
  id, title, description, program_details, scheduled_at, duration_minutes,
  is_recurring, recurrence_rule, livekit_room_name,
  arabic_text, transliteration, french_translation, verified_references, recommended_repetitions, status
) VALUES
  (
    '55555555-5555-4555-8555-000000000001',
    'Rassemblement Hebdomadaire de Dhikr — Samedi 20h00 GMT',
    'Session spirituelle collective apaisée dédiée au rappel d''Allah, à la gratitude et à la fraternité, sans classement ni compétition.',
    '20h00 GMT : Ouverture & intention sincère • 20h05 : Tasbih, Tahmid & Takbir • 20h25 : Invocation de paix et de constance • 20h40 : Rappel bref et clôture.',
    DATE_TRUNC('week', NOW() AT TIME ZONE 'UTC') + INTERVAL '5 days 20 hours',
    45,
    TRUE,
    'WEEKLY;BYDAY=SA;BYHOUR=20;BYMINUTE=0;TZ=UTC',
    'yitte-zikr-saturday-2000-gmt',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'SubhānAllāhi wa bi-ḥamdih, SubhānAllāhi l-ʿAẓīm',
    'Gloire et louange à Allah, Gloire à Allah l''Immense.',
    '[{"source": "Sahih al-Bukhari", "reference": "n° 6406 & 7563"}, {"source": "Sahih Muslim", "reference": "n° 2694"}]'::jsonb,
    33,
    'scheduled'
  ),
  (
    '55555555-5555-4555-8555-000000000002',
    'Méditation Spirituelle : Tahlīl & Gratitude',
    'Session d''apaisement intérieur centrée sur l''unicité divine et la reconnaissance.',
    'Lecture posée, méditation sur le sens et invocations authentiques.',
    DATE_TRUNC('week', NOW() AT TIME ZONE 'UTC') + INTERVAL '2 days 19 hours',
    30,
    TRUE,
    'WEEKLY;BYDAY=WE;BYHOUR=19;BYMINUTE=0;TZ=UTC',
    'yitte-zikr-wednesday-1900-gmt',
    'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    'Lā ilāha illAllāhu waḥdahu lā sharīka lah, lahu l-mulku wa lahu l-ḥamdu wa huwa ʿalā kulli shayʾin qadīr',
    'Il n''y a de divinité digne d''adoration qu''Allah, Seul sans associé ; à Lui appartient la royauté, à Lui la louange et Il est Omnipotent.',
    '[{"source": "Sahih al-Bukhari", "reference": "n° 3293"}, {"source": "Sahih Muslim", "reference": "n° 2691"}]'::jsonb,
    33,
    'scheduled'
  )
ON CONFLICT (id) DO NOTHING;

-- 6. YITTÉ CHALLENGE Starter Bank
INSERT INTO challenges (
  id, title, description, category, format, difficulty, time_limit_seconds,
  instructions, evaluation_criteria, options, correct_answer, explanation, verified_references, language
) VALUES
  (
    '66666666-6666-4666-8666-000000000001',
    'L''automatisation par l''IA renforce-t-elle nécessairement l''esprit critique humain ?',
    'Défi d''analyse nuancée sur le rapport entre outils d''intelligence artificielle et autonomie intellectuelle.',
    'technology',
    'yes_no_depends',
    'intermediate',
    300,
    'Choisissez Oui, Non ou Cela dépend, puis justifiez votre position en identifiant au moins deux facteurs conditionnels.',
    '["Clarté de la thèse", "Identification des conditions", "Exemples concrets", "Absence de généralisation abusive"]'::jsonb,
    '["Oui", "Non", "Cela dépend"]'::jsonb,
    'Cela dépend',
    'Tout dépend de l''usage pédagogique : utilisée comme tuteur socratique et vérificateur, l''IA stimule l''esprit critique ; utilisée comme substitut de réflexion, elle l''atrophie.',
    '["UNESCO Guidance for Generative AI in Education and Research (2023)"]'::jsonb,
    'fr'
  ),
  (
    '66666666-6666-4666-8666-000000000002',
    'Distinguer consensus doctrinal et effort d''interprétation contemporain',
    'Exercice d''argumentation structurée sur la méthode intellectuelle dans la pensée islamique.',
    'islamic_thought',
    'argumentation',
    'advanced',
    420,
    'Rédigez une argumentation structurée distinguant les fondements textuels établis (thawabit) et les espaces d''ijtihad contextuel (mutaghayyirat).',
    '["Distinction faits/interprétations", "Rigueur méthodologique", "Nuance et respect académique"]'::jsonb,
    NULL,
    NULL,
    'La tradition savante distingue les principes constants établis par des textes univoques des applications conjoncturelles ouvertes à la délibération raisonnée.',
    '["Al-Shatibi, Al-Muwafaqat fi Usul al-Shari''a"]'::jsonb,
    'fr'
  ),
  (
    '66666666-6666-4666-8666-000000000003',
    'Réponse Vocale : Quelle discipline personnelle transforme durablement une communauté ?',
    'Défi d''expression orale de 2 minutes évaluant cohérence, exemples et clarté.',
    'ethics',
    'audio_response',
    'intermediate',
    180,
    'Enregistrez un plaidoyer structuré (max 3 min) reliant discipline individuelle et responsabilité collective.',
    '["Pertinence (20)", "Logique (25)", "Profondeur (20)", "Exemples (15)", "Nuance (10)", "Clarté (10)"]'::jsonb,
    NULL,
    NULL,
    'Une argumentation convaincante relie l''éthique personnelle (constance, honnêteté, maîtrise du temps) à ses effets mesurables sur la confiance et l''entraide collective.',
    '["Éthique pratique & leadership communautaire"]'::jsonb,
    'fr'
  )
ON CONFLICT (id) DO NOTHING;

-- 7. Weekly Topic & Career Opportunities Starter
INSERT INTO weekly_topics (
  id, week_number, year, title, introduction, guiding_questions, category, starts_at, ends_at
) VALUES
  (
    '77777777-7777-4777-8777-000000000001',
    46,
    2026,
    'Comment concilier ambition professionnelle, excellence scientifique et vie spirituelle équilibrée ?',
    'Cette semaine, notre cercle explore la notion d''excellence (Ihsan) appliquée aux études, au travail et à l''engagement citoyen sans tomber dans l''épuisement ou le cloisonnement.',
    '["Quelles habitudes concrètes protègent la concentration à l''ère numérique ?", "Comment transformer la compétence technique en service utile à la société ?", "Quelle place accorder à la communauté dans la progression individuelle ?"]'::jsonb,
    'spirituality',
    NOW() - INTERVAL '1 day',
    NOW() + INTERVAL '6 days'
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO career_opportunities (
  id, title, organization, opportunity_type, domain, location, description, deadline
) VALUES
  (
    '88888888-8888-4888-8888-000000000001',
    'Programme Mentorat Ingénierie IA & Systèmes Distribués',
    'Collectif Boroom Yitté Tech',
    'mentorship',
    'artificial_intelligence',
    'En ligne (Francophone & Anglophone)',
    'Accompagnement de 8 semaines : architecture logicielle, revue de CV technique, simulations d''entretiens et projet open-source.',
    NOW() + INTERVAL '30 days'
  ),
  (
    '88888888-8888-4888-8888-000000000002',
    'Parcours Certification Cybersécurité & Gestion de Projet',
    'Académie Yitté Pro',
    'certification',
    'cybersecurity',
    'En ligne',
    'Préparation guidée en français et en anglais aux fondamentaux de la sécurité applicative, gouvernance des données et gestion agile.',
    NOW() + INTERVAL '45 days'
  )
ON CONFLICT (id) DO NOTHING;
