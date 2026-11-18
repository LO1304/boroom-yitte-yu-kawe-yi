import 'package:livekit_client/livekit_client.dart';

class LiveKitVoiceService {
  Room? _room;
  bool _connected = false;
  bool _micMuted = false;

  bool get isConnected => _connected;
  bool get isMicMuted => _micMuted;
  Room? get room => _room;

  Future<void> connect({
    required String livekitUrl,
    required String token,
    bool publishAudio = true,
  }) async {
    await disconnect();
    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: AudioPublishOptions(dtx: true),
      ),
    );
    await room.connect(livekitUrl, token);
    _room = room;
    _connected = true;
    if (publishAudio) {
      await room.localParticipant?.setMicrophoneEnabled(true);
      _micMuted = false;
    } else {
      _micMuted = true;
    }
  }

  Future<void> toggleMic() async {
    if (_room?.localParticipant == null) return;
    _micMuted = !_micMuted;
    await _room!.localParticipant!.setMicrophoneEnabled(!_micMuted);
  }

  Future<void> disconnect() async {
    if (_room != null) {
      await _room!.disconnect();
      await _room!.dispose();
      _room = null;
    }
    _connected = false;
  }
}
