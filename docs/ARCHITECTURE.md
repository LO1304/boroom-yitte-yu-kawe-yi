# Architecture Technique — BOROOM YITTÉ YU KAWÉ YI (v2.0)

## 1. Vue d'ensemble du système

**BOROOM YITTÉ YU KAWÉ YI** (*S'élever individuellement, grandir collectivement*) repose sur une architecture découplée orientée production :

```
+-------------------------------------------------------------------+
|               Application Mobile Flutter (Android, iOS & Web)    |
|  - Riverpod / State Controllers   - GoRouter & Deep Links         |
|  - Design System Sanctuaire (Émeraude/Ivoire/Laiton + Sombre)     |
|  - Bibliothèque Docs (5 domaines/40 sous-cat., zéro invention IA) |
|  - Extra Groupe (mensuel) & Accès Exclusif Membres (Nom Complet)  |
|  - Pont WhatsApp Officiel (lien chat.whatsapp.com, wa.me, .txt)   |
|  - Multilingue (FR principal + EN, AR RTL, WO)                   |
|  - Enregistrement Audio + Permissions Micro + Cache Hors-Ligne    |
|  - Générateur PDF (résumés, bilans, rapports de progression)      |
+---------------------------------+---------------------------------+
                                  | HTTPS / WSS / WebRTC
        +-------------------------+-------------------------+
        v                                                   v
+---------------------------------------+     +----------------------------+
|         Supabase Platform             |     |     LiveKit WebRTC Cloud   |
|  - Auth (Email, Magic Link, Invites)  |     |  - Salons vocaux Zikr      |
|  - PostgreSQL + 50 Tables + RLS       |     |  - English Conversations   |
|  - Realtime (Quiz, Débats, Messages)  |     |  - Débats & Ateliers Live  |
|  - Storage (Audio privé, Docs, PDF)   |     +----------------------------+
|  - Edge Functions (Deno/TS)           |
+-------------------+-------------------+
                    | Clés secrètes côté serveur uniquement
                    v
+-------------------------------------------------------------------+
|               Passerelle IA & STT Indépendante                    |
|  - Fournisseurs LLM : Gemini (défaut), OpenAI, Anthropic, Custom  |
|  - STT : Deepgram Nova-2 (défaut), OpenAI Whisper                 |
|  - 7 Agents spécialisés + Quotas journaliers + Suivi des coûts    |
|  - Push Notifications : FCM (Android) & APNs (iOS)                |
+-------------------------------------------------------------------+
```

## 2. Principes d'intégrité, d'éthique et de sécurité

1. **Zéro clé secrète côté mobile** : Seules `SUPABASE_URL` et `SUPABASE_ANON_KEY` (publiques par conception avec RLS) sont transmises au client Flutter via `--dart-define-from-file`. Les clés `GEMINI_API_KEY`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `DEEPGRAM_API_KEY`, `LIVEKIT_API_SECRET` et `SUPABASE_SERVICE_ROLE_KEY` vivent exclusivement dans l'environnement serveur des Supabase Edge Functions.
2. **Confidentialité stricte des données personnelles** :
   - Les tables `private_notes`, `personal_goals`, `habits`, `reading_tracker` et `zikr_participations` sont protégées par Row Level Security (`auth.uid() = user_id`), inaccessibles même aux administrateurs.
3. **Éthique spirituelle (YITTÉ ZIKR)** :
   - Aucun classement, score de piété ni badge de pratique religieuse n'est calculé ou affiché publiquement.
4. **Équité IA (Face-à-Face & English Club)** :
   - Évaluation aveugle à l'identité, la foi, l'accent ou l'impopularité d'une opinion.
   - Pondération transparente à 100 points validée côté serveur (`normalizeDebateRubric`, `normalizeEnglishRubric`).
   - Droit de recours humain (`debate_review_requests`) et consentement audio explicite (`voice_recordings.consent_granted` + politique de rétention + job `retention-cleanup`).
5. **Validation éditoriale des résumés IA** :
   - Contrainte SQL `CHECK (status <> 'published' OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL))` garantissant qu'aucun résumé généré par `YITTE_SUMMARIZER` n'est publié sans validation humaine d'un `content_editor` ou `admin`.
6. **Stratégie de sauvegarde et reprise (Backup & Recovery)** :
   - Sauvegardes quotidiennes automatisées PostgreSQL (Supabase PITR / Point-in-Time Recovery recommandé en production).
   - Migrations SQL versionnées et idempotentes dans `supabase/migrations/`.
   - Exportation chiffrée des métadonnées d'audit (`audit_logs`) et purge planifiée des audios expirés (`retention-cleanup`).
