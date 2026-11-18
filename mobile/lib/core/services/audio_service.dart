import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'local_file_bridge.dart';
import 'speech_bridge.dart';

class AudioService {
  AudioService();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Future<bool> ensureMicrophonePermission() async {
    if (kIsWeb) {
      if (!SpeechBridge.isSecureAudioContext) return false;
      return _recorder.hasPermission();
    }
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final req = await Permission.microphone.request();
    return req.isGranted;
  }

  Future<String?> startRecording({required String prefix}) async {
    if (kIsWeb && !SpeechBridge.isSecureAudioContext) {
      throw StateError(
        'Le microphone navigateur nécessite une connexion sécurisée HTTPS ou localhost (127.0.0.1).',
      );
    }

    final allowed = await ensureMicrophonePermission();
    if (!allowed) {
      throw StateError('Permission microphone refusée.');
    }

    if (kIsWeb) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final attempts = [
        (encoder: AudioEncoder.opus, ext: 'webm'),
        (encoder: AudioEncoder.aacLc, ext: 'm4a'),
        (encoder: AudioEncoder.wav, ext: 'wav'),
      ];
      Object? lastError;
      for (final attempt in attempts) {
        try {
          final path = '${prefix}_$stamp.${attempt.ext}';
          await _recorder.start(
            RecordConfig(
              encoder: attempt.encoder,
              bitRate: 96000,
              sampleRate: 44100,
            ),
            path: path,
          );
          _isRecording = true;
          return path;
        } catch (e) {
          lastError = e;
        }
      }
      throw StateError('Encodeur micro navigateur indisponible : $lastError');
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 96000,
        sampleRate: 44100,
      ),
      path: path,
    );
    _isRecording = true;
    return path;
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  Future<Uint8List?> readRecordedBytes(String path) async {
    if (kIsWeb) {
      return SpeechBridge.readBlobBytes(path);
    }
    return localFileReadBytes(path);
  }

  Future<void> playFile(
    String filePath, {
    void Function()? onEnded,
    void Function(String error)? onError,
  }) async {
    if (kIsWeb) {
      await SpeechBridge.playAudioUrl(
        filePath,
        onEnded: onEnded,
        onError: onError,
      );
      return;
    }
    try {
      if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
        await _player.setUrl(filePath);
      } else {
        if (!localFileExists(filePath)) {
          onError?.call('Fichier audio local introuvable.');
          return;
        }
        await _player.setFilePath(filePath);
      }
      await _player.play();
      onEnded?.call();
    } catch (e) {
      onError?.call('Lecture audio impossible : $e');
    }
  }

  Future<void> stopPlayback() async {
    if (kIsWeb) {
      SpeechBridge.stopAudioPlayback();
      return;
    }
    await _player.stop();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}
