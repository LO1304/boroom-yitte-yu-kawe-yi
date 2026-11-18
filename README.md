# BOROOM YITTÉ YU KAWÉ YI — Version 2.0

> *« S'élever individuellement, grandir collectivement. »*

Écosystème numérique complet (Mobile Android & iOS + Backend Supabase/PostgreSQL + Passerelle IA multi-fournisseurs + WebRTC LiveKit) réunissant développement intellectuel, éducation islamique et spirituelle apaisée, débats vocaux évalués par IA, tournois de quiz, apprentissage de l'anglais, progression professionnelle et journal personnel confidentiel.

## Structure du Dépôt

- **`mobile/`** : Application Flutter & Dart (Android, iOS & Web) structurée par domaines fonctionnels (`auth`, `home`, `reflections`, `documents`, `extra_groupe`, `notifications`, `challenges`, `debates`, `quiz_arena`, `zikr`, `english_club`, `professional`, `personal_growth`, `community`, `admin`, `settings`) avec Design System Sanctuaire (`YitteColors`, `YitteSurfaceTokens`, `SanctuaryGeometryPainter`).
- **`supabase/migrations/`** : **13 migrations PostgreSQL** (dont `202611180013_documents_extra_groupe_topics.sql`) couvrant les **39+ tables** spécifiées, clés étrangères, index, contraintes d'intégrité, triggers, publications Realtime, buckets Storage et Row Level Security (RLS).
- **`supabase/functions/`** : 8 Edge Functions Deno/TypeScript :
  - `ai-gateway` : Routeur sécurisé vers les 7 agents IA (`YITTE_DEBATE_AI`, `YITTE_ENGLISH_COACH`, `YITTE_QUIZ_MASTER`, `YITTE_SPIRITUAL_ASSISTANT`, `YITTE_CAREER_COACH`, `YITTE_PERSONAL_MENTOR`, `YITTE_SUMMARIZER`) avec quotas et suivi des coûts.
  - `stt-transcribe` : Transcription vocale (Deepgram / OpenAI Whisper) soumise au consentement explicite.
  - `debate-evaluate` : Grille transparente à 100 points aveugle à l'identité, à l'accent et à la croyance.
  - `english-evaluate` : Évaluation orale CEFR A1–C2 (`en-GB` / `en-US`) respectueuse des accents.
  - `quiz-engine` : Validation serveur anti-triche, chronomètre et génération de tournois 8/16/32.
  - `livekit-token` : Émission de jetons LiveKit WebRTC avec modération côté serveur.
  - `admin-actions` : Gouvernance RBAC à 5 rôles, invitations, validation de résumés, rapports et diffusions.
  - `retention-cleanup` : Purge automatisée selon les préférences de rétention audio.
- **`supabase/tests/`** : Tests automatisés Node.js validant le schéma SQL, RLS et la logique des grilles/tournois.
- **`docs/`** : `ARCHITECTURE.md`, `DESIGN_SYSTEM.md`, `CREDENTIALS_AND_CONFIG.md`.

## Démarrage Rapide

1. **Tests Backend** :
   ```bash
   node supabase/tests/validate_all.mjs
   ```
2. **Analyse & Tests Flutter** :
   ```bash
   cd mobile
   flutter pub get
   flutter analyze
   flutter test
   ```
3. **Configuration Cloud & Builds** : Consultez [docs/CREDENTIALS_AND_CONFIG.md](docs/CREDENTIALS_AND_CONFIG.md).
