import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

bool localFileExists(String path) => File(path).existsSync();

int localFileLength(String path) => File(path).lengthSync();

Future<Uint8List?> localFileReadBytes(String path) async {
  final file = File(path);
  if (!file.existsSync()) return null;
  return file.readAsBytes();
}

Future<void> uploadLocalRecording({
  required SupabaseClient client,
  required String bucket,
  required String storagePath,
  required String filePath,
}) async {
  await client.storage.from(bucket).upload(storagePath, File(filePath));
}
