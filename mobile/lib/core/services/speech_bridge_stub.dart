import 'dart:async';
import 'dart:typed_data';

class SpeechBridge {
  SpeechBridge._();

  static bool get isTtsSupported => false;
  static bool get isSttSupported => false;
  static bool get isSecureAudioContext => true;

  static Future<Uint8List?> readBlobBytes(String url) async => null;

  static void speak(
    String text, {
    String locale = 'en-GB',
    double rate = 0.96,
    bool preferFemale = false,
    String? voiceProfile,
    String? bundledAssetPath,
    void Function(bool isSpeaking)? onSpeakingChanged,
    void Function(int wordIndex)? onWordIndex,
    void Function(String engine)? onEngineUsed,
  }) {}

  static void stopSpeaking() {}

  static bool startDictation({
    required String locale,
    required void Function(String transcript) onTranscript,
    void Function(String error)? onError,
  }) {
    onError?.call(
      'La dictée Web temps réel est active sur navigateur ; utilisez le bouton Enregistrer natif sur mobile.',
    );
    return false;
  }

  static void stopDictation() {}

  static Future<void> playAudioUrl(
    String url, {
    void Function()? onEnded,
    void Function(String error)? onError,
  }) async {}

  static void stopAudioPlayback() {}

  static bool downloadBytes(
    Uint8List bytes,
    String filename, {
    String mimeType = 'application/pdf',
  }) =>
      false;

  static Future<void> showWebNotification(String title, String body) async {}

  static StreamSubscription<void>? subscribeLiveEvents(
    void Function() onRemoteChange,
  ) =>
      null;
}
