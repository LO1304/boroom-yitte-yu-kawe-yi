import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/domain_models.dart';
import 'speech_bridge.dart';

class PdfExportService {
  const PdfExportService._();

  static const _emerald = PdfColor.fromInt(0xFF0B4F3F);
  static const _gold = PdfColor.fromInt(0xFFC89B3C);

  /// Normalizes punctuation and non-WinAnsi characters so built-in PDF Type1
  /// fonts never emit missing-glyph warnings in offline tests or exports.
  static String _pdfSafe(String input) {
    final normalized = input
        .replaceAll('\u2022', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2019', "'")
        .replaceAll('\u2018', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u00AB', '"')
        .replaceAll('\u00BB', '"')
        .replaceAll('\u2026', '...')
        .replaceAll('\u0153', 'oe')
        .replaceAll('\u0152', 'OE');

    final buffer = StringBuffer();
    for (final rune in normalized.runes) {
      if (rune == 0x0A || rune == 0x0D || rune == 0x09) {
        buffer.writeCharCode(rune);
      } else if (rune >= 0x20 && rune <= 0xFF) {
        buffer.writeCharCode(rune);
      } else {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  static pw.Widget _bulletItem(
    String text, {
    pw.TextStyle style = const pw.TextStyle(fontSize: 11),
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5, right: 8),
            child: pw.Container(
              width: 4,
              height: 4,
              decoration: const pw.BoxDecoration(
                color: _gold,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.Expanded(child: pw.Text(_pdfSafe(text), style: style)),
        ],
      ),
    );
  }

  static Future<Uint8List> buildSummaryPdf({
    required String title,
    required String subtitle,
    required String bodyMarkdown,
    List<String> bulletPoints = const [],
    List<String> references = const [],
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BOROOM YITTÉ YU KAWÉ YI',
              style: pw.TextStyle(
                color: _emerald,
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Container(height: 2, color: _gold),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (ctx) => [
          pw.Text(
            _pdfSafe(title),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _emerald,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            _pdfSafe(subtitle),
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            _pdfSafe(bodyMarkdown),
            style: const pw.TextStyle(fontSize: 11.5, lineSpacing: 4),
          ),
          if (bulletPoints.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Points Clés',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _emerald,
              ),
            ),
            pw.SizedBox(height: 6),
            ...bulletPoints.map(
              (item) => _bulletItem(
                item,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          ],
          if (references.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Références Vérifiées',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _emerald,
              ),
            ),
            pw.SizedBox(height: 6),
            ...references.map(
              (r) => _bulletItem(
                r,
                style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.grey800),
              ),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> buildDebateEvaluationPdf({
    required DebateMatchModel match,
    required DebateRubricBreakdown rubric,
  }) {
    final bullets = <String>[
      'Pertinence : ${rubric.relevance.toStringAsFixed(1)} / 20',
      'Raisonnement logique : ${rubric.logicalReasoning.toStringAsFixed(1)} / 25',
      'Profondeur d\'analyse : ${rubric.depthOfAnalysis.toStringAsFixed(1)} / 20',
      'Arguments & exemples : ${rubric.argumentsAndExamples.toStringAsFixed(1)} / 15',
      'Esprit critique & nuance : ${rubric.criticalNuance.toStringAsFixed(1)} / 10',
      'Clarté de communication : ${rubric.clarity.toStringAsFixed(1)} / 10',
      'TOTAL : ${rubric.totalScore.toStringAsFixed(1)} / 100',
      ...rubric.recommendations.map((r) => 'Conseil : $r'),
    ];

    return buildSummaryPdf(
      title: 'Évaluation Face-à-Face : ${match.topicTitle}',
      subtitle:
          'Question : ${match.topicQuestion} - Catégorie : ${match.category}',
      bodyMarkdown: rubric.explanation,
      bulletPoints: bullets,
      references: rubric.verifiedReferences,
    );
  }

  static Future<void> previewAndSharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (kIsWeb) {
      final ok = SpeechBridge.downloadBytes(
        bytes,
        filename,
        mimeType: 'application/pdf',
      );
      if (ok) return;
    }
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static Future<void> sharePlainText(String text, {String? subject}) async {
    try {
      await Share.share(text, subject: subject);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }
}
