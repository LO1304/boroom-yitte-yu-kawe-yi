# Guide des Identifiants Externes et Configuration Production

Tous les composants (application mobile Flutter, migrations SQL, RLS, Edge Functions IA/STT/LiveKit/Admin) sont implémentés dans ce dépôt. Pour connecter un environnement cloud **en production**, renseignez les éléments suivants (sans jamais les commiter) :

## 1. Supabase (Backend, Auth, PostgreSQL, Storage, Realtime)
1. Créez un projet Supabase sur [supabase.com](https://supabase.com).
2. Liez et poussez les migrations + données initiales :
   ```bash
   npx supabase login
   npx supabase link --project-ref VOTRE_PROJECT_REF
   npx supabase db push
   ```
3. Configurez les variables d'application Flutter dans `mobile/env.dev.json` (copié depuis `.env.example`) :
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

## 2. Passerelle IA & Speech-to-Text (Côté Serveur Edge Functions uniquement)
Définissez les secrets sur Supabase (`npx supabase secrets set ...`) :
- **Fournisseur IA par défaut (Gemini)** : `AI_DEFAULT_PROVIDER=gemini`, `GEMINI_API_KEY=...`
- **Fournisseurs alternatifs optionnels** : `OPENAI_API_KEY=...`, `ANTHROPIC_API_KEY=...`, `CUSTOM_LLM_BASE_URL=...`
- **Speech-to-Text (STT)** : `STT_DEFAULT_PROVIDER=deepgram`, `DEEPGRAM_API_KEY=...` (ou `OPENAI_WHISPER_API_KEY=...`)
- Déployez toutes les Edge Functions :
  ```bash
  npx supabase functions deploy ai-gateway stt-transcribe debate-evaluate english-evaluate quiz-engine livekit-token admin-actions retention-cleanup
  ```

## 3. Salons Vocaux LiveKit (WebRTC)
1. Créez un projet sur [livekit.io](https://livekit.io) ou auto-hébergez un serveur LiveKit.
2. Ajoutez les secrets Edge Functions :
   - `LIVEKIT_URL` (`wss://...`)
   - `LIVEKIT_API_KEY`
   - `LIVEKIT_API_SECRET`

## 4. Notifications Push (Android FCM & iOS APNs)
- **Android** : Créez un projet Firebase, téléchargez `google-services.json` dans `mobile/android/app/google-services.json`, et configurez `FCM_PROJECT_ID` + `FCM_SERVICE_ACCOUNT_JSON`.
- **iOS** : Téléchargez `GoogleService-Info.plist` dans `mobile/ios/Runner/GoogleService-Info.plist`, activez la capacité *Push Notifications* & *Background Modes* dans Xcode, et configurez la clé `.p8` APNs dans Firebase Console.

## 5. Signature & Publication Mobile (Stores)
- **Android Release / Google Play AAB** : Générez un keystore (`keytool -genkey ...`) et configurez `mobile/android/key.properties` avant publication sur Google Play Console.
- **iOS IPA** : Exige macOS + Xcode + un compte Apple Developer Program pour le profil de provisionnement, la signature et le téléversement vers App Store Connect.
