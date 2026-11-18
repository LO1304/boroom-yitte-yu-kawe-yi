import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

bool localFileExists(String path) => false;

int localFileLength(String path) => 0;

Future<Uint8List?> localFileReadBytes(String path) async => null;

Future<void> uploadLocalRecording({
  required SupabaseClient client,
  required String bucket,
  required String storagePath,
  required String filePath,
}) async {
  // Web uploads are handled via browser audio blobs / bytes rather than dart:io File paths.
}
