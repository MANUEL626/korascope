import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../competitors/competitors.service.dart';
import '../reports/reports.service.dart';

class DashboardMetric {
  final String value;
  final String label;
  final String hint;
  final bool attention;

  const DashboardMetric({
    required this.value,
    required this.label,
    required this.hint,
    this.attention = false,
  });
}

class MarketActivity {
  final String title;
  final String subtitle;
  final String badge;

  const MarketActivity({
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}

class HomeService extends ChangeNotifier {
  final ApiClient apiClient;

  HomeService({required this.apiClient});

  List<Competitor> competitors = const [];
  List<WatchReport> reports = const [];
  bool isLoading = false;
  bool hasLoaded = false;
  String? error;
  DateTime? lastUpdated;

  int get totalCompetitors => competitors.length;
  int get activeCompetitors =>
      competitors.where((competitor) => competitor.active).length;
  int get inactiveCompetitors => totalCompetitors - activeCompetitors;
  int get reportCount => reports.length;
  int get recentReportCount => reports.where((report) => report.isNew).length;

  List<DashboardMetric> metrics(int interestCount) => [
    DashboardMetric(
      value: '$activeCompetitors',
      label: 'Concurrents actifs',
      hint: totalCompetitors == 0
          ? 'Aucune entreprise configurée'
          : '$totalCompetitors au total',
      attention: activeCompetitors == 0,
    ),
    DashboardMetric(
      value: '$inactiveCompetitors',
      label: 'En pause',
      hint: inactiveCompetitors == 0
          ? 'Tout est actif'
          : 'À réactiver si besoin',
      attention:
          inactiveCompetitors > activeCompetitors && totalCompetitors > 0,
    ),
    DashboardMetric(
      value: '$reportCount',
      label: 'Rapports',
      hint: recentReportCount == 0
          ? 'Aucun nouveau rapport'
          : '$recentReportCount récent(s)',
      attention: reportCount == 0,
    ),
    DashboardMetric(
      value: '$interestCount',
      label: 'Centres d’intérêt',
      hint: interestCount == 0 ? 'À compléter' : 'Recherche mieux ciblée',
      attention: interestCount == 0,
    ),
  ];

  List<MarketActivity> get activities {
    final items = <MarketActivity>[
      for (final report in reports.take(3))
        MarketActivity(
          title: report.title,
          subtitle: report.summary.isEmpty
              ? 'Rapport disponible'
              : report.summary,
          badge: report.isNew ? 'NOUVEAU' : 'RAPPORT',
        ),
      for (final competitor in competitors.take(4))
        MarketActivity(
          title: competitor.name,
          subtitle: competitor.active
              ? 'Surveillance active'
              : 'Surveillance désactivée',
          badge: competitor.active ? 'ACTIF' : 'INACTIF',
        ),
    ];
    return items.take(5).toList(growable: false);
  }

  String get priorityMessage {
    if (activeCompetitors == 0) {
      return 'Activez au moins un concurrent pour commencer la veille.';
    }
    if (reports.isEmpty) {
      return 'Aucun rapport disponible pour le moment. Les prochains rapports apparaîtront ici.';
    }
    if (recentReportCount > 0) {
      return '$recentReportCount nouveau(x) rapport(s) à consulter.';
    }
    return 'Votre veille est configurée. Consultez les derniers rapports pour suivre les signaux.';
  }

  Future<void> loadForUser(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final responses = await Future.wait([
        apiClient.get(
          '/competitor-companies/utilisateurs/$userId?activeOnly=false',
        ),
        apiClient.get('/reports/utilisateurs/$userId'),
      ]);
      competitors = (responses[0] as List<dynamic>)
          .map((item) => Competitor.fromJson(item as Map<String, dynamic>))
          .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
          .toList(growable: false);
      reports = (responses[1] as List<dynamic>)
          .map((item) => WatchReport.fromJson(item as Map<String, dynamic>))
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
      hasLoaded = true;
      lastUpdated = DateTime.now();
    } catch (exception) {
      error = exception is ApiException
          ? exception.message
          : 'Impossible de charger la vue d’ensemble.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
