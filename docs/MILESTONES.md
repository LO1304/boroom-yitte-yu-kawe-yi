# Feuille de Route & Implémentation — Milestones 1 à 10

| Milestone | Périmètre | Implémentation Principale |
|---|---|---|
| **M1** | Architecture, BDD PostgreSQL, RLS & Design System | 12 migrations SQL (`supabase/migrations/`), 39+ tables requises + tables complémentaires, RLS sur chaque table, Design System Émeraude/Ivoire/Or/Charbon (`app_theme.dart`), architecture FR/EN/AR(RTL)/WO (`app_localizations.dart`). |
| **M2** | Auth, Onboarding & Dashboard | Onboarding interactif (`onboarding_screen.dart`), Auth Supabase + code d'invitation (`auth_screen.dart`), Dashboard 5 onglets (`home_dashboard_screen.dart`, `app_router.dart`). |
| **M3** | Réflexions, Discussions & Bibliothèque | Publications, commentaires, réactions, favoris, pièces jointes, sujet hebdomadaire, synthèses IA soumises à revue éditeur, bibliothèque permanente, export PDF (`reflections_screen.dart`). |
| **M4** | Défis & Yitté Face-à-Face | 10 catégories, 7 formats (`challenges_screen.dart`), débats vocaux avec minuterie de préparation, enregistrement consentement-dépendant 3 min, STT, grille 100 pts à 6 critères, demande de révision humaine (`debates_screen.dart`, `debate-evaluate`). |
| **M5** | Yitté Quiz Arena & Tournois | Modes 1v1, Équipe, 8/16/32 joueurs, championnat hebdomadaire, anti-triche changement de focus et temps serveur, explications vérifiées, classement éducatif volontaire (`quiz_arena_screen.dart`, `quiz-engine`). |
| **M6** | Yitté Zikr & Spiritualité | Rassemblement Samedi 20h00 GMT, texte arabe RTL, translittération, traduction française, références vérifiées (Sahih Bukhari/Muslim), compteur Tasbih personnel privé, rappels, zéro classement de piété (`zikr_screen.dart`). |
| **M7** | Yitté English Club | Modules A–J, 5 mots quotidiens (API UK/US), CEFR A1–C2, enregistrement & évaluation orale IA équitable vis-à-vis de l'accent (`english_club_screen.dart`, `english-evaluate`). |
| **M8** | Professionnel & Développement Personnel | CV, lettre, recruteur IA, projets & opportunités (`professional_screen.dart`) ; journal strictement privé, objectifs, habitudes, lectures, mentor IA (`personal_growth_screen.dart`). |
| **M9** | Administration, Sécurité & Notifications | Console RBAC 5 rôles, invitations, validation résumés, modération/rapports, diffusion notifications FCM/APNs, suivi coûts IA & journaux d'audit (`admin_dashboard_screen.dart`, `admin-actions`). |
| **M10** | Tests, Optimisation & Builds Mobiles | Suite SQL/Backend (`validate_all.mjs`), tests Flutter (`ecosystem_test.dart`), builds Android APK Debug / Release / AppBundle AAB et configuration CI iOS/IPA (`.github/workflows/ci_mobile.yml`). |
