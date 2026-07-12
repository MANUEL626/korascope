import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';

class WatchReport {
  final String id;
  final String title;
  final String date;
  final String content;
  final String utilisateurId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WatchReport({
    required this.id,
    required this.title,
    required this.date,
    required this.content,
    required this.utilisateurId,
    this.createdAt,
    this.updatedAt,
  });

  factory WatchReport.fromJson(Map<String, dynamic> json) => WatchReport(
    id: json['id']?.toString() ?? '',
    title: json['name']?.toString() ?? 'Rapport sans titre',
    date: json['date']?.toString() ?? '',
    content: json['contenu']?.toString() ?? '',
    utilisateurId: json['utilisateurId']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
  );

  String get plainTextContent => _htmlToPlainText(content);

  String get summary {
    final compact = plainTextContent.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 150) return compact;
    return '${compact.substring(0, 150)}…';
  }

  bool get isNew {
    final reference = createdAt ?? updatedAt;
    if (reference == null) return false;
    return DateTime.now().difference(reference).inDays < 2;
  }
}

class ReportsService extends ChangeNotifier {
  final ApiClient apiClient;

  ReportsService({required this.apiClient});

  List<WatchReport> _reports = const [];
  bool isLoading = false;
  bool hasLoaded = false;
  String? error;

  List<WatchReport> search(String query) => _reports
      .where(
        (report) => report.title.toLowerCase().contains(query.toLowerCase()),
      )
      .toList(growable: false);

  Future<void> loadForUser(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data =
          await apiClient.get('/reports/utilisateurs/$userId') as List<dynamic>;
      _reports = data
          .map((item) => WatchReport.fromJson(item as Map<String, dynamic>))
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
      hasLoaded = true;
    } catch (exception) {
      error = exception is ApiException
          ? exception.message
          : 'Impossible de récupérer les rapports.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<WatchReport> getById(String id) async {
    final data = await apiClient.get('/reports/$id') as Map<String, dynamic>;
    return WatchReport.fromJson(data);
  }
}

String _htmlToPlainText(String html) {
  if (html.trim().isEmpty) return '';
  var text = html;
  text = text.replaceAll(
    RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
    ' ',
  );
  text = text.replaceAll(
    RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true),
    ' ',
  );
  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(
    RegExp(r'</(p|div|section|article|h[1-6])>', caseSensitive: false),
    '\n\n',
  );
  text = text.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ');
  text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'</(ul|ol)>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
  text = _decodeHtmlEntities(text);
  text = text.replaceAll(RegExp(r'[ \t\f\r]+'), ' ');
  text = text.replaceAll(RegExp(r' *\n *'), '\n');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return text.trim();
}

String _decodeHtmlEntities(String value) {
  var text = value
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");

  text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final code = int.tryParse(match.group(1) ?? '');
    if (code == null) return match.group(0)!;
    return String.fromCharCode(code);
  });
  text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
    final code = int.tryParse(match.group(1) ?? '', radix: 16);
    if (code == null) return match.group(0)!;
    return String.fromCharCode(code);
  });
  return text;
}
