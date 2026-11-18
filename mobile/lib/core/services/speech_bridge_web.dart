import 'dart:async';
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
}

@JS('Blob')
extension type _JsBlob._(JSObject _) implements JSObject {
  external factory _JsBlob(JSArray<JSAny?> parts, [JSObject options]);
}

class SpeechBridge {
  SpeechBridge._();

  static JSObject? _activeRecognition;
  static JSObject? _activeAudio;

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

  static void speak(String text, {String locale = 'en-GB'}) {
    try {
      final synthAny = _window['speechSynthesis'];
      if (synthAny == null || !synthAny.isA<JSObject>()) return;
      final synth = synthAny as JSObject;
      synth.callMethod('cancel'.toJS);
      final utt = _SpeechUtterance(text.toJS);
      utt.lang = locale.toJS;
      utt.rate = (0.95).toJS;
      synth.callMethod('speak'.toJS, utt);
    } catch (_) {
      // Ignore smoothly if browser audio is blocked or unsupported
    }
  }

  static void stopSpeaking() {
    try {
      final synthAny = _window['speechSynthesis'];
      if (synthAny == null || !synthAny.isA<JSObject>()) return;
      (synthAny as JSObject).callMethod('cancel'.toJS);
    } catch (_) {}
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
        onError?.call('Dictée micro : $err');
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
