class WatchReport {
  final String title;
  final String date;
  final String summary;
  final bool isNew;
  const WatchReport({
    required this.title,
    required this.date,
    required this.summary,
    this.isNew = false,
  });
}

class ReportsService {
  final reports = const [
    WatchReport(
      title: 'Rapport hebdomadaire • 23 juin',
      date: 'Généré il y a 2 h',
      summary:
          '3 nouvelles campagnes détectées et une hausse SEO notable chez NovaPay.',
      isNew: true,
    ),
    WatchReport(
      title: 'Analyse trimestrielle Q2',
      date: '15 juin 2026',
      summary:
          'Consolidation des parts de voix, contenus et évolutions de prix.',
    ),
    WatchReport(
      title: 'Veille Tech Afrique',
      date: '08 juin 2026',
      summary:
          'Levées de fonds, recrutements clés et lancements produits du secteur.',
    ),
  ];

  List<WatchReport> search(String query) => reports
      .where(
        (report) => report.title.toLowerCase().contains(query.toLowerCase()),
      )
      .toList(growable: false);
}
