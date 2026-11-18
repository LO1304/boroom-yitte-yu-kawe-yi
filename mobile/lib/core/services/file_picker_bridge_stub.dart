import 'file_picker_bridge.dart';

class FilePickerBridge {
  FilePickerBridge._();

  static bool get isSupported => false;

  static Future<PickedDocumentFile?> pickDocumentFile() async => null;
}
