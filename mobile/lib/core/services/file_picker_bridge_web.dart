import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'file_picker_bridge.dart';

@JS('document')
external JSObject get _document;

class FilePickerBridge {
  FilePickerBridge._();

  static bool get isSupported => true;

  static Future<PickedDocumentFile?> pickDocumentFile() async {
    final completer = Completer<PickedDocumentFile?>();
    try {
      final input =
          _document.callMethod('createElement'.toJS, 'input'.toJS) as JSObject;
      input['type'] = 'file'.toJS;
      input['accept'] =
          '.pdf,.doc,.docx,.ppt,.pptx,.txt,.md,.csv,.png,.jpg,.jpeg,.webp'.toJS;

      input['onchange'] = ((JSAny? _) async {
        try {
          final filesAny = input['files'];
          if (filesAny == null || !filesAny.isA<JSObject>()) {
            if (!completer.isCompleted) completer.complete(null);
            return;
          }
          final fileAny =
              (filesAny as JSObject).callMethod('item'.toJS, 0.toJS);
          if (fileAny == null || !fileAny.isA<JSObject>()) {
            if (!completer.isCompleted) completer.complete(null);
            return;
          }
          final file = fileAny as JSObject;
          final nameAny = file['name'];
          final name = (nameAny != null && nameAny.isA<JSString>())
              ? (nameAny as JSString).toDart
              : 'document.txt';

          final abPromise = file.callMethod('arrayBuffer'.toJS);
          if (abPromise == null || !abPromise.isA<JSPromise>()) {
            if (!completer.isCompleted) completer.complete(null);
            return;
          }
          final abAny = await (abPromise as JSPromise).toDart;
          if (abAny == null || !abAny.isA<JSArrayBuffer>()) {
            if (!completer.isCompleted) completer.complete(null);
            return;
          }
          final byteBuf = (abAny as JSArrayBuffer).toDart;
          final uint8 = byteBuf.asUint8List();

          final dot = name.lastIndexOf('.');
          final ext =
              dot >= 0 ? name.substring(dot + 1).toLowerCase() : 'txt';
          String? extracted;
          if (ext == 'txt' || ext == 'md' || ext == 'csv') {
            extracted = utf8.decode(uint8, allowMalformed: true).trim();
          }

          if (!completer.isCompleted) {
            completer.complete(
              PickedDocumentFile(
                fileName: name,
                extension: ext,
                sizeBytes: uint8.length,
                bytes: Uint8List.fromList(uint8),
                extractedText: extracted,
              ),
            );
          }
        } catch (_) {
          if (!completer.isCompleted) completer.complete(null);
        }
      }).toJS;

      input['oncancel'] = ((JSAny? _) {
        if (!completer.isCompleted) completer.complete(null);
      }).toJS;

      input.callMethod('click'.toJS);
      return await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    }
  }
}
