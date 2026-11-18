export 'file_picker_bridge_stub.dart'
    if (dart.library.js_interop) 'file_picker_bridge_web.dart';

class PickedDocumentFile {
  final String fileName;
  final String extension;
  final int sizeBytes;
  final List<int> bytes;
  final String? extractedText;

  const PickedDocumentFile({
    required this.fileName,
    required this.extension,
    required this.sizeBytes,
    required this.bytes,
    this.extractedText,
  });
}
