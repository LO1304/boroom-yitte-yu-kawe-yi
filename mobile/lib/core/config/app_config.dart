/// Application configuration populated via `--dart-define` or `--dart-define-from-file`.
/// Secret AI, STT, and Service Role keys are NEVER placed in the mobile client.
class AppConfig {
  const AppConfig._();

  static const String appName = 'BOROOM YITTÉ YU KAWÉ YI';
  static const String tagline = "S'élever individuellement, grandir collectivement.";

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String appScheme = String.fromEnvironment(
    'APP_SCHEME',
    defaultValue: 'boroomyitte',
  );

  static const String appWebOrigin = String.fromEnvironment(
    'APP_WEB_ORIGIN',
    defaultValue: 'https://app.boroomyitte.org',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty &&
      !supabaseUrl.contains('YOUR_PROJECT_REF');

  /// External credentials checklist surfaced honestly in Settings / Admin.
  static List<CredentialRequirement> get externalCredentialsChecklist => [
        CredentialRequirement(
          name: 'Supabase Project (SUPABASE_URL & SUPABASE_ANON_KEY)',
          configured: isSupabaseConfigured,
          scope: 'Mobile (--dart-define)',
          purpose: 'Auth, PostgreSQL, Realtime, Storage & Edge Functions',
        ),
        const CredentialRequirement(
          name: 'Server AI Provider Key (GEMINI_API_KEY / OPENAI_API_KEY / ANTHROPIC_API_KEY)',
          configured: false,
          scope: 'Supabase Edge Function Secrets',
          purpose: '7 agents IA spécialisés (YITTE_DEBATE_AI, YITTE_ENGLISH_COACH, etc.)',
        ),
        const CredentialRequirement(
          name: 'Speech-to-Text Key (DEEPGRAM_API_KEY / OPENAI_WHISPER_API_KEY)',
          configured: false,
          scope: 'Supabase Edge Function Secrets',
          purpose: 'Transcription des débats vocaux, anglais oral et entretiens',
        ),
        const CredentialRequirement(
          name: 'LiveKit WebRTC (LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET)',
          configured: false,
          scope: 'Supabase Edge Function Secrets',
          purpose: 'Salons audio temps réel (Zikr, English Rooms, Ateliers)',
        ),
        const CredentialRequirement(
          name: 'Firebase Cloud Messaging & APNs (google-services.json / GoogleService-Info.plist)',
          configured: false,
          scope: 'Android / iOS Native Config + Server',
          purpose: 'Notifications push natives en arrière-plan',
        ),
      ];
}

class CredentialRequirement {
  final String name;
  final bool configured;
  final String scope;
  final String purpose;

  const CredentialRequirement({
    required this.name,
    required this.configured,
    required this.scope,
    required this.purpose,
  });
}
