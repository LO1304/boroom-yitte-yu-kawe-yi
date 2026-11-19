import 'dart:convert';
import 'dart:typed_data';

import 'external_link_bridge.dart';
import 'speech_bridge.dart';

/// Exports announcements and scheduled community sessions into standard RFC 5545 (.ics)
/// calendar files or opens a pre-filled 1-click Google Calendar event.
class CalendarExportService {
  const CalendarExportService._();

  static String _formatUtcStamp(DateTime dt) {
    final u = dt.toUtc();
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${u.year}${p2(u.month)}${p2(u.day)}T${p2(u.hour)}${p2(u.minute)}${p2(u.second)}Z';
  }

  static String _escapeIcs(String raw) {
    return raw
        .replaceAll(r'\', r'\\')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;');
  }

  static String buildIcsContent({
    required String title,
    required String description,
    DateTime? start,
    Duration duration = const Duration(hours: 1),
    String? location,
  }) {
    final startTime = start ?? DateTime.now().add(const Duration(days: 1));
    final endTime = startTime.add(duration);
    final uid = 'yitte-${startTime.millisecondsSinceEpoch}@boroomyitte.app';
    final buf = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//BOROOM YITTE YU KAWE YI//Agenda//FR')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('METHOD:PUBLISH')
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:$uid')
      ..writeln('DTSTAMP:${_formatUtcStamp(DateTime.now())}')
      ..writeln('DTSTART:${_formatUtcStamp(startTime)}')
      ..writeln('DTEND:${_formatUtcStamp(endTime)}')
      ..writeln('SUMMARY:${_escapeIcs(title.trim())}')
      ..writeln('DESCRIPTION:${_escapeIcs(description.trim())}');
    if (location != null && location.trim().isNotEmpty) {
      buf.writeln('LOCATION:${_escapeIcs(location.trim())}');
    }
    buf
      ..writeln('END:VEVENT')
      ..writeln('END:VCALENDAR');
    return buf.toString();
  }

  static String buildGoogleCalendarUrl({
    required String title,
    required String description,
    DateTime? start,
    Duration duration = const Duration(hours: 1),
    String? location,
  }) {
    final startTime = start ?? DateTime.now().add(const Duration(days: 1));
    final endTime = startTime.add(duration);
    final dates = '${_formatUtcStamp(startTime)}/${_formatUtcStamp(endTime)}';
    final params = <String, String>{
      'action': 'TEMPLATE',
      'text': title.trim(),
      'dates': dates,
      'details': description.trim(),
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
    };
    return Uri.https('calendar.google.com', '/calendar/render', params)
        .toString();
  }

  /// Downloads a standard `.ics` file (works with Apple Calendar, Outlook, Samsung, Google)
  /// or falls back to opening Google Calendar if running on a platform without web download.
  static Future<bool> addEventToCalendar({
    required String title,
    required String description,
    DateTime? start,
    Duration duration = const Duration(hours: 1),
    String? location,
    bool preferGoogleCalendar = false,
  }) async {
    if (preferGoogleCalendar) {
      final url = buildGoogleCalendarUrl(
        title: title,
        description: description,
        start: start,
        duration: duration,
        location: location,
      );
      return ExternalLinkBridge.openUrl(url);
    }

    final ics = buildIcsContent(
      title: title,
      description: description,
      start: start,
      duration: duration,
      location: location,
    );
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final filename = '${slug.isEmpty ? "annonce_boroom_yitte" : slug}.ics';
    final downloaded = SpeechBridge.downloadBytes(
      Uint8List.fromList(utf8.encode(ics)),
      filename,
      mimeType: 'text/calendar;charset=utf-8',
    );
    if (downloaded) return true;

    final url = buildGoogleCalendarUrl(
      title: title,
      description: description,
      start: start,
      duration: duration,
      location: location,
    );
    return ExternalLinkBridge.openUrl(url);
  }
}
