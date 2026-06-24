import 'package:flutter/foundation.dart';

class DashboardMetric {
  final String value;
  final String label;
  final String trend;
  const DashboardMetric(this.value, this.label, this.trend);
}

class MarketActivity {
  final String company;
  final String activity;
  final String impact;
  const MarketActivity(this.company, this.activity, this.impact);
}

class HomeService extends ChangeNotifier {
  final metrics = const [
    DashboardMetric('5', 'Concurrents suivis', '+12%'),
    DashboardMetric('12', 'Nouveaux contenus', '+8%'),
    DashboardMetric('3', 'Publicités trouvées', '+2'),
    DashboardMetric('SEO', 'Meilleure progression', '+4,2%'),
  ];

  final activities = const [
    MarketActivity('NovaPay', 'Nouvelle tarification', 'ÉLEVÉ'),
    MarketActivity('Cinet', 'Article de blog', 'MOYEN'),
    MarketActivity('AfriCloud', 'Campagne LinkedIn', 'FAIBLE'),
  ];

  DateTime lastUpdated = DateTime.now();

  Future<void> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    lastUpdated = DateTime.now();
    notifyListeners();
  }
}
