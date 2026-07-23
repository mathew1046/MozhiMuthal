import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../data/models/session_model.dart';

class DeicInfo {
  final String name;
  final String address;
  final String phone;

  const DeicInfo({
    required this.name,
    required this.address,
    required this.phone,
  });

  factory DeicInfo.fromJson(Map<String, dynamic> json) => DeicInfo(
    name: json['name'] as String,
    address: json['address'] as String,
    phone: json['phone'] as String,
  );
}

class ReferralGenerator {
  static Map<String, DeicInfo>? _deicData;

  static Future<Map<String, DeicInfo>> _loadDeicData() async {
    if (_deicData != null) return _deicData!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/deic_data.json');
      final Map<String, dynamic> data = json.decode(jsonStr);
      _deicData = data.map(
        (key, value) =>
            MapEntry(key, DeicInfo.fromJson(value as Map<String, dynamic>)),
      );
    } catch (_) {
      _deicData = {};
    }
    return _deicData!;
  }

  static Future<DeicInfo?> getDeicByDistrict(String districtCode) async {
    final data = await _loadDeicData();
    return data[districtCode];
  }

  static Future<Uint8List> buildReferralPdf(SessionModel session) async {
    final deic = await getDeicByDistrict(session.districtCode);
    final pdf = pw.Document();
    final analysis = session.questionnaireAnalysis;
    final domains = _mapList(analysis['domains']);
    final concerns = _mapList(analysis['questions']).where((question) {
      final severity = _text(question['severity']).toLowerCase();
      return severity.isNotEmpty &&
          severity != 'normal' &&
          severity != 'reminder';
    }).toList();
    final isQuestionnaireOnly = session.analysisStatus == 'SKIPPED';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (context) => pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            'MozhiMuthal developmental monitoring - not a diagnosis',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (context) => [
          pw.Text(
            'MozhiMuthal Developmental Screening Referral',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          _pdfSection('Referral details', [
            _pdfRow(
              'Screening date',
              DateFormat('dd MMM yyyy').format(session.sessionDate),
            ),
            _pdfRow('Screening outcome', session.riskLevel.name.toUpperCase()),
            _pdfRow('Child name', _blankAsNotProvided(session.childName)),
            _pdfRow('Child age', '${session.childAgeMonths} months'),
            _pdfRow(
              'Date of birth',
              session.childBirthDate == null
                  ? 'Not provided'
                  : DateFormat('dd MMM yyyy').format(session.childBirthDate!),
            ),
            _pdfRow('Anganwadi ID', _blankAsNotProvided(session.anganwadiId)),
            _pdfRow(
              'District',
              session.districtCode.isEmpty
                  ? 'Not provided'
                  : session.districtCode,
            ),
          ]),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Acoustic voice screening',
            isQuestionnaireOnly
                ? [
                    pw.Text(
                      'Voice test was skipped. No acoustic measurements were created.',
                    ),
                  ]
                : [
                    _pdfRow('Analysis status', session.analysisStatus),
                    _pdfRow(
                      'VTTL',
                      '${session.vttlMs.toStringAsFixed(0)} ms (${_flagLabel(session.vttlFlagged)})',
                    ),
                    _pdfRow(
                      'CVR ratio',
                      '${session.cvrRatio.toStringAsFixed(3)} (${_flagLabel(session.cvrFlagged)})',
                    ),
                    _pdfRow(
                      'PFV',
                      session.pfvInsufficientData
                          ? 'Insufficient data'
                          : '${(session.pfvRawSemitoneSD ?? session.pfvStd).toStringAsFixed(2)} semitone SD (${_flagLabel(session.pfvFlagged)})',
                    ),
                    _pdfRow(
                      'Child voiced time',
                      '${session.childVoicedSeconds.toStringAsFixed(1)} seconds',
                    ),
                    if (session.qualityReasons.isNotEmpty)
                      _pdfRow(
                        'Recording notes',
                        session.qualityReasons.join('; '),
                      ),
                  ],
          ),
          pw.SizedBox(height: 14),
          _pdfSection('Parent developmental questionnaire', [
            _pdfRow(
              'Questionnaire result',
              '${_blankAsNotProvided(analysis['tier'])} - ${_blankAsNotProvided(session.questionnaireState)}',
            ),
            if (_text(analysis['message']).isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(_text(analysis['message'])),
              ),
            if (domains.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                'Domain insights',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              ...domains.map(
                (domain) => _pdfLine(
                  '${_text(domain['domain'])}: ${_text(domain['status']).replaceAll('_', ' ')}. ${_text(domain['explanation'])}',
                ),
              ),
            ],
            if (concerns.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                'Answers needing attention',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              ...concerns.map((question) {
                final questionData = _map(question['question']);
                final prompt = _text(questionData['text']).isNotEmpty
                    ? _text(questionData['text'])
                    : 'Question ${_text(question['question_id'])}';
                return _pdfLine(
                  '$prompt - ${_text(question['answer'])} (${_text(question['severity'])})',
                );
              }),
            ],
          ]),
          pw.SizedBox(height: 14),
          pw.Text(
            'Further developmental evaluation at a DEIC centre is recommended.',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (deic != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Nearest DEIC',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(deic.name),
            pw.Text(deic.address),
            pw.Text('Phone: ${deic.phone}'),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _pdfSection(String title, List<pw.Widget> children) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...children,
          ],
        ),
      );

  static pw.Widget _pdfRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(text: value),
        ],
      ),
    ),
  );

  static pw.Widget _pdfLine(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 2),
    child: pw.Text('- $text'),
  );

  static String _flagLabel(bool flagged) =>
      flagged ? 'flagged' : 'within range';
  static String _blankAsNotProvided(Object? value) {
    final text = _text(value);
    return text.isEmpty ? 'Not provided' : text;
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};
  static List<Map<String, dynamic>> _mapList(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : const [];
}
