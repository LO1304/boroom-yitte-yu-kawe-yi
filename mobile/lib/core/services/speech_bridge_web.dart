import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

@JS('window')
external JSObject get _window;

@JS('document')
external JSObject get _document;

@JS('URL')
external JSObject get _urlApi;

@JS('SpeechSynthesisUtterance')
extension type _SpeechUtterance._(JSObject _) implements JSObject {
  external factory _SpeechUtterance(JSString text);
  external set lang(JSString value);
  external set rate(JSNumber value);
  external set pitch(JSNumber value);
  external set voice(JSObject? value);
}

@JS('Blob')
extension type _JsBlob._(JSObject _) implements JSObject {
  external factory _JsBlob(JSArray<JSAny?> parts, [JSObject options]);
}

class SpeechBridge {
  SpeechBridge._();

  static JSObject? _activeRecognition;
  static JSObject? _activeAudio;
  static JSObject? _ttsAudio;
  static Timer? _wordTicker;
  static int _speakToken = 0;
  static void Function(bool isSpeaking)? _activeSpeakingCb;
  static void Function(int wordIndex)? _activeWordCb;
  static String? _chatterboxSamplePath;
  static final Map<String, String> _chatterboxAudioCache = {};
  static const _chatterboxBase = 'https://resembleai-chatterbox.hf.space';

  static bool get isTtsSupported {
    try {
      return _window.has('speechSynthesis');
    } catch (_) {
      return false;
    }
  }

  static bool get isSttSupported {
    try {
      return _window.has('SpeechRecognition') ||
          _window.has('webkitSpeechRecognition');
    } catch (_) {
      return false;
    }
  }

  static bool get isSecureAudioContext {
    try {
      final sec = _window['isSecureContext'];
      if (sec != null && sec.isA<JSBoolean>()) {
        return (sec as JSBoolean).toDart;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<Uint8List?> readBlobBytes(String url) async {
    try {
      if (!url.startsWith('blob:')) return null;
      final resPromise = _window.callMethod('fetch'.toJS, url.toJS);
      if (resPromise == null || !resPromise.isA<JSPromise>()) return null;
      final resAny = await (resPromise as JSPromise).toDart;
      if (resAny == null || !resAny.isA<JSObject>()) return null;
      final bufPromise = (resAny as JSObject).callMethod('arrayBuffer'.toJS);
      if (bufPromise == null || !bufPromise.isA<JSPromise>()) return null;
      final bufAny = await (bufPromise as JSPromise).toDart;
      if (bufAny == null || !bufAny.isA<JSArrayBuffer>()) return null;
      return (bufAny as JSArrayBuffer).toDart.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static bool get _canUseLocalNeuralApi {
    try {
      final host = Uri.base.host.toLowerCase();
      return host.isNotEmpty && !host.endsWith('github.io');
    } catch (_) {
      return false;
    }
  }

  static ({JSObject voice, bool isNatural})? _pickBestVoice(
    JSObject synth,
    String locale, {
    required bool preferFemale,
    String? voiceProfile,
  }) {
    try {
      final voicesAny = synth.callMethod('getVoices'.toJS);
      if (voicesAny == null || !voicesAny.isA<JSArray>()) return null;
      final list = (voicesAny as JSArray).toDart;
      if (list.isEmpty) return null;

      final targetLang = locale.toLowerCase();
      final shortLang = targetLang.split('-').first;
      final profileHint = switch (voiceProfile) {
        'amy-soft-uk' => 'libby',
        'amy-clear-uk' => 'sonia',
        'amy-warm-us' => 'emma',
        'amy-fluent-us' => 'ava',
        _ => '',
      };

      const naturalFemaleHints = [
        'ava',
        'emma',
        'libby',
        'sonia',
        'jenny',
        'aria',
        'samantha',
        'serena',
        'martha',
        'kate',
        'karen',
        'moira',
        'fiona',
        'amy',
        'google uk english female',
        'google us english',
      ];
      const legacyFemaleHints = ['zira', 'hazel', 'susan', 'victoria', 'female'];
      const maleHints = [
        'george',
        'david',
        'mark',
        'daniel',
        'guy',
        'ryan',
        'brian',
        'andrew',
        'christopher',
        'male',
        'google uk english male',
      ];

      JSObject? bestVoice;
      bool bestIsNatural = false;
      int bestScore = -9999;

      for (final vAny in list) {
        if (vAny == null || !vAny.isA<JSObject>()) continue;
        final v = vAny as JSObject;
        final nameAny = v['name'];
        final langAny = v['lang'];
        final name = (nameAny != null && nameAny.isA<JSString>())
            ? (nameAny as JSString).toDart.toLowerCase()
            : '';
        final vLang = (langAny != null && langAny.isA<JSString>())
            ? (langAny as JSString).toDart.toLowerCase()
            : '';
        if (!vLang.startsWith(shortLang)) continue;

        final isExact = vLang == targetLang || vLang.startsWith(targetLang);
        final isNatural = name.contains('natural') ||
            name.contains('neural') ||
            name.contains('online') ||
            name.contains('enhanced') ||
            name.contains('premium');
        final isGoogle = name.contains('google');
        final isLegacyDesktop = name.contains('desktop') ||
            name.contains('zira') ||
            name.contains('david') ||
            name.contains('hazel');
        final isNaturalFemale = naturalFemaleHints.any((h) => name.contains(h));
        final isLegacyFemale = legacyFemaleHints.any((h) => name.contains(h));
        final isMale = maleHints.any((h) => name.contains(h));

        int score = 0;
        if (isExact) score += 35;
        if (profileHint.isNotEmpty && name.contains(profileHint)) score += 90;
        if (isNatural) score += 120;
        if (isGoogle) score += 85;
        if (isLegacyDesktop) score -= 55;
        if (preferFemale) {
          if (isNaturalFemale) score += 50;
          if (isLegacyFemale) score += 15;
          if (isMale) score -= 140;
        }

        if (score > bestScore) {
          bestScore = score;
          bestVoice = v;
          bestIsNatural = isNatural || isGoogle;
        }
      }

      if (bestVoice == null) return null;
      return (voice: bestVoice, isNatural: bestIsNatural);
    } catch (_) {
      return null;
    }
  }

  static List<double> _buildWordCumulativeWeights(List<String> words) {
    if (words.isEmpty) return const [];
    final weights = <double>[];
    double total = 0;
    for (final w in words) {
      final len = w.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').length.clamp(2, 14);
      final pauseBonus = RegExp(r'[.!?;:]$').hasMatch(w)
          ? 4.0
          : (w.endsWith(',') ? 2.0 : 0.0);
      total += len + pauseBonus;
      weights.add(total);
    }
    return weights.map((v) => total > 0 ? v / total : 1.0).toList();
  }

  static void _playNeuralAudioUrl({
    required String url,
    required String fullText,
    required double playbackRate,
    required int token,
    required String engineLabel,
    String? fallbackAssetUrl,
    required void Function() onFallbackWebSpeech,
    void Function(bool isSpeaking)? onSpeakingChanged,
    void Function(int wordIndex)? onWordIndex,
    void Function(String engine)? onEngineUsed,
  }) {
    try {
      final audioCtor = _window['Audio'];
      if (audioCtor == null || !audioCtor.isA<JSFunction>()) {
        onFallbackWebSpeech();
        return;
      }
      final audio = (audioCtor as JSFunction).callAsConstructor<JSObject>(url.toJS);
      audio['preload'] = 'auto'.toJS;
      audio['playbackRate'] = playbackRate.clamp(0.7, 1.3).toJS;

      final words = fullText
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      final cumWeights = _buildWordCumulativeWeights(words);

      void startWordSync() {
        _wordTicker?.cancel();
        _wordTicker = Timer.periodic(const Duration(milliseconds: 65), (_) {
          if (token != _speakToken || _ttsAudio == null) {
            _wordTicker?.cancel();
            return;
          }
          try {
            final durAny = audio['duration'];
            final curAny = audio['currentTime'];
            final dur = (durAny != null && durAny.isA<JSNumber>())
                ? (durAny as JSNumber).toDartDouble
                : 0.0;
            final cur = (curAny != null && curAny.isA<JSNumber>())
                ? (curAny as JSNumber).toDartDouble
                : 0.0;
            if (dur.isFinite && dur > 0.05 && cumWeights.isNotEmpty) {
              final p = (cur / dur).clamp(0.0, 0.999);
              int idx = 0;
              for (int i = 0; i < cumWeights.length; i++) {
                if (p <= cumWeights[i]) {
                  idx = i;
                  break;
                }
              }
              onWordIndex?.call(idx);
            }
          } catch (_) {}
        });
      }

      audio['onplay'] = ((JSAny? _) {
        if (token != _speakToken) return;
        onEngineUsed?.call(engineLabel);
        onSpeakingChanged?.call(true);
        startWordSync();
      }).toJS;

      audio['onended'] = ((JSAny? _) {
        if (token != _speakToken) return;
        _wordTicker?.cancel();
        _ttsAudio = null;
        onWordIndex?.call(-1);
        onSpeakingChanged?.call(false);
      }).toJS;

      audio['onerror'] = ((JSAny? _) {
        if (token != _speakToken) return;
        _wordTicker?.cancel();
        _ttsAudio = null;
        if (fallbackAssetUrl != null && fallbackAssetUrl.isNotEmpty) {
          _playNeuralAudioUrl(
            url: fallbackAssetUrl,
            fullText: fullText,
            playbackRate: playbackRate,
            token: token,
            engineLabel: 'Voix Neurale Studio (Intégrée)',
            fallbackAssetUrl: null,
            onFallbackWebSpeech: onFallbackWebSpeech,
            onSpeakingChanged: onSpeakingChanged,
            onWordIndex: onWordIndex,
            onEngineUsed: onEngineUsed,
          );
        } else {
          onFallbackWebSpeech();
        }
      }).toJS;

      _ttsAudio = audio;
      final playPromise = audio.callMethod('play'.toJS);
      if (playPromise != null && playPromise.isA<JSPromise>()) {
        (playPromise as JSPromise).toDart.catchError((_) {
          if (token == _speakToken) {
            _wordTicker?.cancel();
            _ttsAudio = null;
            onFallbackWebSpeech();
          }
          return null;
        });
      }
    } catch (_) {
      onFallbackWebSpeech();
    }
  }

  static void _speakWithNaturalWebSpeech({
    required String text,
    required String locale,
    required double rate,
    required bool preferFemale,
    String? voiceProfile,
    required int token,
    void Function(bool isSpeaking)? onSpeakingChanged,
    void Function(int wordIndex)? onWordIndex,
    void Function(String engine)? onEngineUsed,
  }) {
    try {
      final synthAny = _window['speechSynthesis'];
      if (synthAny == null || !synthAny.isA<JSObject>()) {
        onSpeakingChanged?.call(false);
        return;
      }
      final synth = synthAny as JSObject;
      synth.callMethod('cancel'.toJS);

      final chunks = text
          .trim()
          .split(RegExp(r'(?<=[.!?;])\s+'))
          .where((c) => c.trim().isNotEmpty)
          .toList();
      if (chunks.isEmpty) return;

      final picked = _pickBestVoice(
        synth,
        locale,
        preferFemale: preferFemale,
        voiceProfile: voiceProfile,
      );
      final engineName = picked?.isNatural == true
          ? 'Voix Naturelle Navigateur'
          : 'Synthèse Vocale Locale';
      onEngineUsed?.call(engineName);

      // Compute starting global word offset per sentence chunk for exact karaoke sync
      final chunkWordOffsets = <int>[];
      int runningWords = 0;
      for (final c in chunks) {
        chunkWordOffsets.add(runningWords);
        runningWords +=
            c.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      }

      void speakChunk(int chunkIdx) {
        if (token != _speakToken) return;
        if (chunkIdx >= chunks.length) {
          onWordIndex?.call(-1);
          onSpeakingChanged?.call(false);
          return;
        }
        final chunk = chunks[chunkIdx];
        final baseWordIdx = chunkWordOffsets[chunkIdx];
        final utt = _SpeechUtterance(chunk.toJS);
        utt.lang = locale.toJS;
        utt.rate = rate.clamp(0.65, 1.3).toJS;
        utt.pitch = (picked?.isNatural == true ? 1.0 : (preferFemale ? 1.03 : 1.0)).toJS;
        if (picked != null) {
          utt.voice = picked.voice;
        }

        utt['onstart'] = ((JSAny? _) {
          if (token != _speakToken) return;
          if (chunkIdx == 0) onSpeakingChanged?.call(true);
          onWordIndex?.call(baseWordIdx);
        }).toJS;

        utt['onboundary'] = ((JSObject ev) {
          if (token != _speakToken) return;
          final charAny = ev['charIndex'];
          if (charAny != null && charAny.isA<JSNumber>()) {
            final charIdx = (charAny as JSNumber).toDartInt.clamp(0, chunk.length);
            final prefix = chunk.substring(0, charIdx).trim();
            final localIdx = prefix.isEmpty
                ? 0
                : prefix.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
            onWordIndex?.call(baseWordIdx + localIdx);
          }
        }).toJS;

        utt['onend'] = ((JSAny? _) {
          if (token != _speakToken) return;
          speakChunk(chunkIdx + 1);
        }).toJS;

        utt['onerror'] = ((JSAny? _) {
          if (token != _speakToken) return;
          onWordIndex?.call(-1);
          onSpeakingChanged?.call(false);
        }).toJS;

        synth.callMethod('speak'.toJS, utt);
      }

      speakChunk(0);
    } catch (_) {
      onSpeakingChanged?.call(false);
    }
  }

  static List<String> _splitIntoAudioChunks(String text, {int maxChars = 172}) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return const [];
    if (normalized.length <= maxChars) return [normalized];

    final sentences = normalized
        .split(RegExp(r'(?<=[.!?;:])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final chunks = <String>[];
    String current = '';

    void pushLongClause(String clause) {
      final words = clause.split(RegExp(r'\s+'));
      String buf = '';
      for (final w in words) {
        if (buf.isEmpty) {
          buf = w;
        } else if (buf.length + 1 + w.length <= maxChars) {
          buf = '$buf $w';
        } else {
          chunks.add(buf);
          buf = w;
        }
      }
      if (buf.isNotEmpty) chunks.add(buf);
    }

    for (final s in sentences) {
      if (s.length > maxChars) {
        if (current.isNotEmpty) {
          chunks.add(current);
          current = '';
        }
        final parts = s.split(RegExp(r'(?<=,)\s+'));
        for (final p in parts) {
          if (p.length <= maxChars) {
            if (current.isEmpty) {
              current = p;
            } else if (current.length + 1 + p.length <= maxChars) {
              current = '$current $p';
            } else {
              chunks.add(current);
              current = p;
            }
          } else {
            if (current.isNotEmpty) {
              chunks.add(current);
              current = '';
            }
            pushLongClause(p);
          }
        }
      } else if (current.isEmpty) {
        current = s;
      } else if (current.length + 1 + s.length <= maxChars) {
        current = '$current $s';
      } else {
        chunks.add(current);
        current = s;
      }
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  static Future<String?> _requestSoundOfTextUrl(
    String chunk,
    String voiceLocale,
  ) async {
    try {
      final opts = JSObject();
      opts['method'] = 'POST'.toJS;
      final headers = JSObject();
      headers['Content-Type'] = 'application/json'.toJS;
      opts['headers'] = headers;
      final escapedText = chunk
          .replaceAll(r'\', r'\\')
          .replaceAll('"', r'\"')
          .replaceAll('\n', ' ');
      opts['body'] =
          '{"engine":"Google","data":{"text":"$escapedText","voice":"$voiceLocale"}}'
              .toJS;

      final postPromise = _window.callMethod(
        'fetch'.toJS,
        'https://api.soundoftext.com/sounds'.toJS,
        opts,
      );
      if (postPromise == null || !postPromise.isA<JSPromise>()) return null;
      final postRes = await (postPromise as JSPromise).toDart;
      if (postRes == null || !postRes.isA<JSObject>()) return null;
      final jsonP = (postRes as JSObject).callMethod('json'.toJS);
      if (jsonP == null || !jsonP.isA<JSPromise>()) return null;
      final postData = await (jsonP as JSPromise).toDart;
      if (postData == null || !postData.isA<JSObject>()) return null;
      final idAny = (postData as JSObject)['id'];
      if (idAny == null || !idAny.isA<JSString>()) return null;
      final id = (idAny as JSString).toDart;

      for (int attempt = 0; attempt < 4; attempt++) {
        await Future<void>.delayed(Duration(milliseconds: attempt == 0 ? 220 : 350));
        final getP = _window.callMethod(
          'fetch'.toJS,
          'https://api.soundoftext.com/sounds/$id'.toJS,
        );
        if (getP == null || !getP.isA<JSPromise>()) continue;
        final getRes = await (getP as JSPromise).toDart;
        if (getRes == null || !getRes.isA<JSObject>()) continue;
        final gJsonP = (getRes as JSObject).callMethod('json'.toJS);
        if (gJsonP == null || !gJsonP.isA<JSPromise>()) continue;
        final gData = await (gJsonP as JSPromise).toDart;
        if (gData == null || !gData.isA<JSObject>()) continue;
        final locAny = (gData as JSObject)['location'];
        if (locAny != null && locAny.isA<JSString>()) {
          final loc = (locAny as JSString).toDart;
          if (loc.startsWith('http')) return loc;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static void _playConsistentCloudQueue({
    required String fullText,
    required String locale,
    required String? voiceProfile,
    required double playbackRate,
    required int token,
    String? offlineAssetUrl,
    required void Function() onFallbackWebSpeech,
    void Function(bool isSpeaking)? onSpeakingChanged,
    void Function(int wordIndex)? onWordIndex,
    void Function(String engine)? onEngineUsed,
  }) {
    final chunks = _splitIntoAudioChunks(fullText);
    if (chunks.isEmpty) return;

    final tl = switch (voiceProfile) {
      'amy-soft-uk' => 'en-GB',
      'amy-clear-uk' => 'en-AU',
      'amy-fluent-us' => 'en-US',
      'amy-warm-us' => 'en-US',
      _ => locale.toLowerCase().startsWith('en-gb') ? 'en-GB' : 'en-US',
    };
    final sotVoice = tl == 'en-AU' ? 'en-GB' : tl;

    final chunkWordOffsets = <int>[];
    int offset = 0;
    for (final c in chunks) {
      chunkWordOffsets.add(offset);
      offset += c.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    }

    void playChunkAt(int idx, {bool useSoundOfText = false}) async {
      if (token != _speakToken) return;
      if (idx >= chunks.length) {
        _wordTicker?.cancel();
        _ttsAudio = null;
        onWordIndex?.call(-1);
        onSpeakingChanged?.call(false);
        return;
      }

      final chunk = chunks[idx];
      final baseOffset = chunkWordOffsets[idx];
      final words =
          chunk.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final cumWeights = _buildWordCumulativeWeights(words);

      String? url;
      if (useSoundOfText) {
        url = await _requestSoundOfTextUrl(chunk, sotVoice);
        if (token != _speakToken) return;
        if (url == null) {
          if (offlineAssetUrl != null && offlineAssetUrl.isNotEmpty && idx == 0) {
            _playNeuralAudioUrl(
              url: offlineAssetUrl,
              fullText: fullText,
              playbackRate: playbackRate,
              token: token,
              engineLabel: 'Voix Amy Intégrée (Hors-ligne)',
              fallbackAssetUrl: null,
              onFallbackWebSpeech: onFallbackWebSpeech,
              onSpeakingChanged: onSpeakingChanged,
              onWordIndex: onWordIndex,
              onEngineUsed: onEngineUsed,
            );
          } else {
            onFallbackWebSpeech();
          }
          return;
        }
      } else {
        url =
            'https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=$tl&q=${Uri.encodeQueryComponent(chunk)}';
      }

      try {
        final audioCtor = _window['Audio'];
        if (audioCtor == null || !audioCtor.isA<JSFunction>()) {
          onFallbackWebSpeech();
          return;
        }
        final audio =
            (audioCtor as JSFunction).callAsConstructor<JSObject>();
        audio['referrerPolicy'] = 'no-referrer'.toJS;
        audio['preload'] = 'auto'.toJS;
        audio['src'] = url.toJS;
        audio['playbackRate'] = playbackRate.clamp(0.72, 1.28).toJS;

        audio['onplay'] = ((JSAny? _) {
          if (token != _speakToken) return;
          if (idx == 0) {
            onEngineUsed?.call(
              useSoundOfText
                  ? 'Voix Amy Fluide (Cloud)'
                  : 'Voix Amy Neurale ($tl)',
            );
            onSpeakingChanged?.call(true);
          }
          _wordTicker?.cancel();
          _wordTicker = Timer.periodic(const Duration(milliseconds: 60), (_) {
            if (token != _speakToken || _ttsAudio == null) {
              _wordTicker?.cancel();
              return;
            }
            try {
              final durAny = audio['duration'];
              final curAny = audio['currentTime'];
              final dur = (durAny != null && durAny.isA<JSNumber>())
                  ? (durAny as JSNumber).toDartDouble
                  : 0.0;
              final cur = (curAny != null && curAny.isA<JSNumber>())
                  ? (curAny as JSNumber).toDartDouble
                  : 0.0;
              if (dur.isFinite && dur > 0.05 && cumWeights.isNotEmpty) {
                final p = (cur / dur).clamp(0.0, 0.999);
                int localIdx = 0;
                for (int i = 0; i < cumWeights.length; i++) {
                  if (p <= cumWeights[i]) {
                    localIdx = i;
                    break;
                  }
                }
                onWordIndex?.call(baseOffset + localIdx);
              }
            } catch (_) {}
          });
        }).toJS;

        audio['onended'] = ((JSAny? _) {
          if (token != _speakToken) return;
          _wordTicker?.cancel();
          playChunkAt(idx + 1, useSoundOfText: useSoundOfText);
        }).toJS;

        audio['onerror'] = ((JSAny? _) {
          if (token != _speakToken) return;
          _wordTicker?.cancel();
          _ttsAudio = null;
          if (!useSoundOfText) {
            playChunkAt(idx, useSoundOfText: true);
          } else if (offlineAssetUrl != null &&
              offlineAssetUrl.isNotEmpty &&
              idx == 0) {
            _playNeuralAudioUrl(
              url: offlineAssetUrl,
              fullText: fullText,
              playbackRate: playbackRate,
              token: token,
              engineLabel: 'Voix Amy Intégrée (Hors-ligne)',
              fallbackAssetUrl: null,
              onFallbackWebSpeech: onFallbackWebSpeech,
              onSpeakingChanged: onSpeakingChanged,
              onWordIndex: onWordIndex,
              onEngineUsed: onEngineUsed,
            );
          } else {
            onFallbackWebSpeech();
          }
        }).toJS;

        _ttsAudio = audio;
        final playPromise = audio.callMethod('play'.toJS);
        if (playPromise != null && playPromise.isA<JSPromise>()) {
          (playPromise as JSPromise).toDart.catchError((_) {
            if (token == _speakToken) {
              _wordTicker?.cancel();
              _ttsAudio = null;
              if (!useSoundOfText) {
                playChunkAt(idx, useSoundOfText: true);
              } else {
                onFallbackWebSpeech();
              }
            }
            return null;
          });
        }
      } catch (_) {
        if (!useSoundOfText) {
          playChunkAt(idx, useSoundOfText: true);
        } else {
          onFallbackWebSpeech();
        }
      }
    }

    playChunkAt(0);
  }

  static Future<String?> _ensureChatterboxSamplePath() async {
    if (_chatterboxSamplePath != null && _chatterboxSamplePath!.isNotEmpty) {
      return _chatterboxSamplePath;
    }
    try {
      // Charge la vraie voix d'Amy directement depuis les assets intégrés
      final assetResAny = await (_window.callMethod(
        'fetch'.toJS,
        'assets/assets/audio/amy/amy_real_intro.ogg'.toJS,
      ) as JSPromise)
          .toDart;
      if (assetResAny == null || !assetResAny.isA<JSObject>()) return null;
      final assetRes = assetResAny as JSObject;
      final okAny = assetRes['ok'];
      if (okAny == null || !okAny.isA<JSBoolean>() || !(okAny as JSBoolean).toDart) {
        return null;
      }
      final blobAny = await (assetRes.callMethod('blob'.toJS) as JSPromise).toDart;
      if (blobAny == null) return null;

      final formDataCtor = _window['FormData'];
      if (formDataCtor == null || !formDataCtor.isA<JSFunction>()) return null;
      final form = (formDataCtor as JSFunction).callAsConstructor<JSObject>();
      form.callMethod(
        'append'.toJS,
        'files'.toJS,
        blobAny,
        'amy_real_intro.ogg'.toJS,
      );

      final opts = <String, Object?>{
        'method': 'POST',
        'body': form,
      }.jsify();
      final upResAny = await (_window.callMethod(
        'fetch'.toJS,
        '$_chatterboxBase/gradio_api/upload'.toJS,
        opts,
      ) as JSPromise)
          .toDart;
      if (upResAny == null || !upResAny.isA<JSObject>()) return null;
      final upTextAny =
          await ((upResAny as JSObject).callMethod('text'.toJS) as JSPromise)
              .toDart;
      if (upTextAny == null || !upTextAny.isA<JSString>()) return null;
      final decoded = jsonDecode((upTextAny as JSString).toDart);
      if (decoded is List && decoded.isNotEmpty && decoded.first is String) {
        _chatterboxSamplePath = decoded.first as String;
        return _chatterboxSamplePath;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _requestChatterboxCloneUrl(String text) async {
    final snippet = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (snippet.isEmpty) return null;
    final clipped = snippet.length > 290 ? snippet.substring(0, 290) : snippet;
    final cached = _chatterboxAudioCache[clipped];
    if (cached != null) return cached;

    Future<String?> runWith(String remotePath) async {
      final payload = jsonEncode({
        'data': [
          clipped,
          {
            'path': remotePath,
            'meta': {'_type': 'gradio.FileData'},
          },
          0.5,
          0.75,
          0,
          0.5,
          false,
        ],
      });
      final callOpts = <String, Object?>{
        'method': 'POST',
        'headers': {'Content-Type': 'application/json'},
        'body': payload,
      }.jsify();
      final callResAny = await (_window.callMethod(
        'fetch'.toJS,
        '$_chatterboxBase/gradio_api/call/generate_tts_audio'.toJS,
        callOpts,
      ) as JSPromise)
          .toDart;
      if (callResAny == null || !callResAny.isA<JSObject>()) return null;
      final callTextAny =
          await ((callResAny as JSObject).callMethod('text'.toJS) as JSPromise)
              .toDart;
      if (callTextAny == null || !callTextAny.isA<JSString>()) return null;
      final callJson = jsonDecode((callTextAny as JSString).toDart);
      final eventId =
          callJson is Map ? callJson['event_id']?.toString() : null;
      if (eventId == null || eventId.isEmpty) return null;

      final sseResAny = await (_window.callMethod(
        'fetch'.toJS,
        '$_chatterboxBase/gradio_api/call/generate_tts_audio/${Uri.encodeComponent(eventId)}'
            .toJS,
      ) as JSPromise)
          .toDart;
      if (sseResAny == null || !sseResAny.isA<JSObject>()) return null;
      final sseTextAny =
          await ((sseResAny as JSObject).callMethod('text'.toJS) as JSPromise)
              .toDart;
      if (sseTextAny == null || !sseTextAny.isA<JSString>()) return null;
      final sseText = (sseTextAny as JSString).toDart;
      if (sseText.contains('event: error')) return null;
      String? dataLine;
      for (final line in sseText.split(RegExp(r'\r?\n'))) {
        if (line.startsWith('data:')) dataLine = line;
      }
      if (dataLine == null) return null;
      final rawData = dataLine.substring(5).trim();
      if (rawData.isEmpty || rawData == 'null') return null;
      final parsed = jsonDecode(rawData);
      if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
        final url = (parsed.first as Map)['url']?.toString();
        if (url != null && url.isNotEmpty) {
          _chatterboxAudioCache[clipped] = url;
          return url;
        }
      }
      return null;
    }

    try {
      final path = await _ensureChatterboxSamplePath();
      if (path == null) return null;
      final url = await runWith(path);
      if (url != null) return url;
      // Retry once with fresh upload in case HF Space cleared /tmp
      _chatterboxSamplePath = null;
      final freshPath = await _ensureChatterboxSamplePath();
      if (freshPath == null) return null;
      return await runWith(freshPath);
    } catch (_) {
      return null;
    }
  }

  static void _speakViaChatterboxDirect({
    required String text,
    required double playbackRate,
    required int token,
    required void Function() onFallbackFluidVoice,
    String? fallbackAssetUrl,
    void Function(bool isSpeaking)? onSpeakingChanged,
    void Function(int wordIndex)? onWordIndex,
    void Function(String engine)? onEngineUsed,
  }) {
    onEngineUsed?.call('chatterbox-cloning');
    _requestChatterboxCloneUrl(text)
        .timeout(const Duration(seconds: 12), onTimeout: () => null)
        .then((audioUrl) {
      if (token != _speakToken) return;
      if (audioUrl == null || audioUrl.isEmpty) {
        // Quota ZeroGPU atteint → bascule immédiate sur la voix féminine fluide (jamais silencieux)
        onFallbackFluidVoice();
        return;
      }
      _playNeuralAudioUrl(
        url: audioUrl,
        fullText: text,
        playbackRate: playbackRate,
        token: token,
        engineLabel: 'Voix réelle clonée d’Amy',
        fallbackAssetUrl: fallbackAssetUrl,
        onFallbackWebSpeech: onFallbackFluidVoice,
        onSpeakingChanged: onSpeakingChanged,
        onWordIndex: onWordIndex,
        onEngineUsed: onEngineUsed,
      );
    });
  }

  static void speak(
    String text, {
    String locale = 'en-GB',
    double rate = 0.96,
    bool preferFemale = false,
    String? voiceProfile,
    String? bundledAssetPath,
    bool strictRealVoiceOnly = false,
    String? voiceServerBaseUrl,
    void Function(bool isSpeaking)? onSpeakingChanged,
    void Function(int wordIndex)? onWordIndex,
    void Function(String engine)? onEngineUsed,
  }) {
    final clean = text.trim();
    if (clean.isEmpty) return;

    stopSpeaking();
    final token = ++_speakToken;
    _activeSpeakingCb = onSpeakingChanged;
    _activeWordCb = onWordIndex;

    final assetUrl = (bundledAssetPath != null && bundledAssetPath.isNotEmpty)
        ? 'assets/$bundledAssetPath'
        : null;

    void fallbackWebSpeech() => _speakWithNaturalWebSpeech(
          text: clean,
          locale: locale,
          rate: rate,
          preferFemale: preferFemale,
          voiceProfile: voiceProfile,
          token: token,
          onSpeakingChanged: onSpeakingChanged,
          onWordIndex: onWordIndex,
          onEngineUsed: onEngineUsed,
        );

    void fallbackFluidCloud() => _playConsistentCloudQueue(
          fullText: clean,
          locale: locale,
          voiceProfile: voiceProfile,
          playbackRate: rate,
          token: token,
          offlineAssetUrl: assetUrl,
          onFallbackWebSpeech: fallbackWebSpeech,
          onSpeakingChanged: onSpeakingChanged,
          onWordIndex: onWordIndex,
          onEngineUsed: onEngineUsed,
        );

    final customBase =
        (voiceServerBaseUrl ?? '').trim().replaceAll(RegExp(r'/+$'), '');
    final hasCloneBackend = customBase.isNotEmpty || _canUseLocalNeuralApi;

    if (strictRealVoiceOnly) {
      if (!hasCloneBackend) {
        // Sur GitHub Pages : tente le clonage gratuit Chatterbox, sinon voix féminine fluide (jamais de silence)
        _speakViaChatterboxDirect(
          text: clean,
          playbackRate: rate,
          token: token,
          fallbackAssetUrl: assetUrl,
          onFallbackFluidVoice: fallbackFluidCloud,
          onSpeakingChanged: onSpeakingChanged,
          onWordIndex: onWordIndex,
          onEngineUsed: onEngineUsed,
        );
        return;
      }
      final resolvedVoice = voiceProfile ??
          (locale.toLowerCase().startsWith('en-gb')
              ? 'amy-soft-uk'
              : 'amy-fluent-us');
      final prefix = customBase.isNotEmpty ? customBase : '';
      final ttsUrl =
          '$prefix/api/tts?text=${Uri.encodeQueryComponent(clean)}&voice=${Uri.encodeQueryComponent(resolvedVoice)}&locale=${Uri.encodeQueryComponent(locale)}&rate=${rate.toStringAsFixed(2)}';
      _playNeuralAudioUrl(
        url: ttsUrl,
        fullText: clean,
        playbackRate: 1.0,
        token: token,
        engineLabel: 'Voix réelle clonée d’Amy',
        fallbackAssetUrl: assetUrl,
        onFallbackWebSpeech: fallbackFluidCloud,
        onSpeakingChanged: onSpeakingChanged,
        onWordIndex: onWordIndex,
        onEngineUsed: onEngineUsed,
      );
      return;
    }

    // 1. Local/LAN server Neural Studio TTS (/api/tts — Edge Neural Ava/Libby/Sonia ou ElevenLabs)
    //    100% homogène sur TOUTES les phrases et mots !
    if (_canUseLocalNeuralApi) {
      final resolvedVoice = voiceProfile ??
          (locale.toLowerCase().startsWith('en-gb')
              ? 'amy-soft-uk'
              : 'amy-fluent-us');
      final ttsUrl =
          '/api/tts?text=${Uri.encodeQueryComponent(clean)}&voice=${Uri.encodeQueryComponent(resolvedVoice)}&locale=${Uri.encodeQueryComponent(locale)}&rate=${rate.toStringAsFixed(2)}';
      _playNeuralAudioUrl(
        url: ttsUrl,
        fullText: clean,
        playbackRate: 1.0,
        token: token,
        engineLabel: 'Voix Neurale Studio',
        fallbackAssetUrl: assetUrl,
        onFallbackWebSpeech: () => _playConsistentCloudQueue(
          fullText: clean,
          locale: locale,
          voiceProfile: voiceProfile,
          playbackRate: rate,
          token: token,
          offlineAssetUrl: assetUrl,
          onFallbackWebSpeech: fallbackWebSpeech,
          onSpeakingChanged: onSpeakingChanged,
          onWordIndex: onWordIndex,
          onEngineUsed: onEngineUsed,
        ),
        onSpeakingChanged: onSpeakingChanged,
        onWordIndex: onWordIndex,
        onEngineUsed: onEngineUsed,
      );
      return;
    }

    // 2. GitHub Pages / Web statique : UNE SEULE VOIX FÉMININE CLOUD MP3 FLUIDE ET HOMOGÈNE
    //    sur 100% des ouvertures, réponses IA, mots cliqués, dialogues et exercices !
    _playConsistentCloudQueue(
      fullText: clean,
      locale: locale,
      voiceProfile: voiceProfile,
      playbackRate: rate,
      token: token,
      offlineAssetUrl: assetUrl,
      onFallbackWebSpeech: fallbackWebSpeech,
      onSpeakingChanged: onSpeakingChanged,
      onWordIndex: onWordIndex,
      onEngineUsed: onEngineUsed,
    );
  }

  static void stopSpeaking() {
    _speakToken++;
    _wordTicker?.cancel();
    _wordTicker = null;
    try {
      _ttsAudio?.callMethod('pause'.toJS);
      _ttsAudio?['currentTime'] = 0.toJS;
    } catch (_) {}
    _ttsAudio = null;
    try {
      final synthAny = _window['speechSynthesis'];
      if (synthAny != null && synthAny.isA<JSObject>()) {
        (synthAny as JSObject).callMethod('cancel'.toJS);
      }
    } catch (_) {}
    _activeWordCb?.call(-1);
    _activeSpeakingCb?.call(false);
    _activeWordCb = null;
    _activeSpeakingCb = null;
  }

  static bool startDictation({
    required String locale,
    required void Function(String transcript) onTranscript,
    void Function(String error)? onError,
  }) {
    try {
      stopDictation();
      final ctorName = _window.has('SpeechRecognition')
          ? 'SpeechRecognition'
          : (_window.has('webkitSpeechRecognition')
              ? 'webkitSpeechRecognition'
              : null);
      if (ctorName == null) {
        onError?.call(
          'Dictée vocale directe non supportée par ce navigateur ; saisissez ou importez un texte.',
        );
        return false;
      }
      final ctorAny = _window[ctorName];
      if (ctorAny == null || !ctorAny.isA<JSFunction>()) return false;
      final ctor = ctorAny as JSFunction;
      final rec = ctor.callAsConstructor<JSObject>();
      rec['lang'] = locale.toJS;
      rec['continuous'] = true.toJS;
      rec['interimResults'] = true.toJS;

      rec['onresult'] = ((JSObject event) {
        final resultsAny = event['results'];
        if (resultsAny == null || !resultsAny.isA<JSObject>()) return;
        final results = resultsAny as JSObject;
        final lenAny = results['length'];
        final length = (lenAny != null && lenAny.isA<JSNumber>())
            ? (lenAny as JSNumber).toDartInt
            : 0;
        final buffer = StringBuffer();
        for (int i = 0; i < length; i++) {
          final itemAny = results.callMethod('item'.toJS, i.toJS);
          if (itemAny == null || !itemAny.isA<JSObject>()) continue;
          final altAny = (itemAny as JSObject).callMethod('item'.toJS, 0.toJS);
          if (altAny == null || !altAny.isA<JSObject>()) continue;
          final tAny = (altAny as JSObject)['transcript'];
          if (tAny != null && tAny.isA<JSString>()) {
            final t = (tAny as JSString).toDart.trim();
            if (t.isNotEmpty) {
              if (buffer.isNotEmpty) buffer.write(' ');
              buffer.write(t);
            }
          }
        }
        onTranscript(buffer.toString());
      }).toJS;

      rec['onerror'] = ((JSObject ev) {
        final errAny = ev['error'];
        final err = (errAny != null && errAny.isA<JSString>())
            ? (errAny as JSString).toDart
            : 'audio-error';
        final friendly = switch (err) {
          'network' =>
            'Dictée temps réel indisponible dans ce navigateur : enregistrez votre voix avec le bouton audio ou saisissez votre réponse.',
          'not-allowed' || 'service-not-allowed' =>
            'Accès au microphone refusé : autorisez le micro dans les paramètres du navigateur.',
          'no-speech' =>
            'Aucune voix détectée : rapprochez-vous du micro et réessayez.',
          'audio-capture' =>
            'Aucun microphone détecté sur cet appareil.',
          _ => 'Dictée vocale interrompue ($err).',
        };
        onError?.call(friendly);
      }).toJS;

      rec.callMethod('start'.toJS);
      _activeRecognition = rec;
      return true;
    } catch (e) {
      onError?.call('Impossible de démarrer la dictée : $e');
      return false;
    }
  }

  static void stopDictation() {
    try {
      _activeRecognition?.callMethod('stop'.toJS);
    } catch (_) {
      // ignore
    } finally {
      _activeRecognition = null;
    }
  }

  static Future<void> playAudioUrl(
    String url, {
    void Function()? onEnded,
    void Function(String error)? onError,
  }) async {
    try {
      stopAudioPlayback();
      final audioCtor = _window['Audio'];
      if (audioCtor == null || !audioCtor.isA<JSFunction>()) {
        onError?.call('Lecteur audio navigateur indisponible.');
        return;
      }
      final audio = (audioCtor as JSFunction).callAsConstructor<JSObject>(url.toJS);
      audio['preload'] = 'auto'.toJS;
      audio['onended'] = ((JSAny? _) {
        _activeAudio = null;
        onEnded?.call();
      }).toJS;
      audio['onerror'] = ((JSAny? _) {
        _activeAudio = null;
        onError?.call('Impossible de lire cet enregistrement audio.');
      }).toJS;
      _activeAudio = audio;
      final playPromise = audio.callMethod('play'.toJS);
      if (playPromise != null && playPromise.isA<JSPromise>()) {
        await (playPromise as JSPromise).toDart;
      }
    } catch (e) {
      onError?.call('Lecture audio bloquée : $e');
    }
  }

  static void stopAudioPlayback() {
    try {
      _activeAudio?.callMethod('pause'.toJS);
      _activeAudio?['currentTime'] = 0.toJS;
    } catch (_) {
      // ignore
    } finally {
      _activeAudio = null;
    }
  }

  static bool downloadBytes(
    Uint8List bytes,
    String filename, {
    String mimeType = 'application/pdf',
  }) {
    try {
      final opts = JSObject();
      opts['type'] = mimeType.toJS;
      final parts = <JSAny?>[bytes.toJS].toJS;
      final blob = _JsBlob(parts, opts);
      final blobUrl = _urlApi.callMethod('createObjectURL'.toJS, blob);
      if (blobUrl == null || !blobUrl.isA<JSString>()) return false;
      final anchor = _document.callMethod('createElement'.toJS, 'a'.toJS) as JSObject;
      anchor['href'] = blobUrl;
      anchor['download'] = filename.toJS;
      anchor.callMethod('click'.toJS);
      Future<void>.delayed(const Duration(seconds: 2), () {
        try {
          _urlApi.callMethod('revokeObjectURL'.toJS, blobUrl);
        } catch (_) {}
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> showWebNotification(String title, String body) async {
    try {
      if (!_window.has('Notification')) return;
      final notifCtor = _window['Notification'];
      if (notifCtor == null || !notifCtor.isA<JSFunction>()) return;
      var permAny = (notifCtor as JSObject)['permission'];
      var perm = permAny != null && permAny.isA<JSString>()
          ? (permAny as JSString).toDart
          : 'default';
      if (perm == 'default') {
        final req = notifCtor.callMethod('requestPermission'.toJS);
        if (req != null && req.isA<JSPromise>()) {
          final res = await (req as JSPromise).toDart;
          if (res != null && res.isA<JSString>()) {
            perm = (res as JSString).toDart;
          }
        }
      }
      if (perm == 'granted') {
        final opts = JSObject();
        opts['body'] = body.toJS;
        (notifCtor as JSFunction).callAsConstructor<JSObject>(title.toJS, opts);
      }
    } catch (_) {}
  }

  static StreamSubscription<void>? subscribeLiveEvents(
    void Function() onRemoteChange,
  ) {
    try {
      if (Uri.base.host.toLowerCase().endsWith('github.io')) return null;
      if (!_window.has('EventSource')) return null;
      final esAny = _window['EventSource'];
      if (esAny == null || !esAny.isA<JSFunction>()) return null;
      final source = (esAny as JSFunction).callAsConstructor<JSObject>('/api/events'.toJS);
      late StreamController<void> controller;
      controller = StreamController<void>(
        onCancel: () {
          try {
            source.callMethod('close'.toJS);
          } catch (_) {}
        },
      );
      source.callMethod(
        'addEventListener'.toJS,
        'snapshot_updated'.toJS,
        ((JSAny? _) {
          onRemoteChange();
          if (!controller.isClosed) controller.add(null);
        }).toJS,
      );
      return controller.stream.listen((_) {});
    } catch (_) {
      return null;
    }
  }
}
