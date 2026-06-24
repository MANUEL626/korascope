import 'package:flutter/foundation.dart';

class Competitor {
  final String name;
  final String website;
  final String sector;
  final int score;
  final double growth;

  const Competitor({
    required this.name,
    required this.website,
    required this.sector,
    required this.score,
    required this.growth,
  });
}

class CompetitorsService extends ChangeNotifier {
  final List<Competitor> _competitors = [
    const Competitor(
      name: 'NovaPay',
      website: 'novapay.io',
      sector: 'Fintech',
      score: 94,
      growth: 12.4,
    ),
    const Competitor(
      name: 'AfriCloud',
      website: 'africloud.com',
      sector: 'Cloud',
      score: 87,
      growth: 8.1,
    ),
    const Competitor(
      name: 'Cinet Labs',
      website: 'cinetlabs.co',
      sector: 'SaaS',
      score: 76,
      growth: -1.2,
    ),
  ];

  List<Competitor> search(String query) => _competitors
      .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
      .toList(growable: false);

  void add({required String name, required String website}) {
    _competitors.add(
      Competitor(
        name: name,
        website: website,
        sector: 'À analyser',
        score: 0,
        growth: 0,
      ),
    );
    notifyListeners();
  }
}
