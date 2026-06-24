import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import 'reports.service.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final service = ReportsService();
  String query = '';

  @override
  Widget build(BuildContext context) {
    final reports = service.search(query);
    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppTopBar(),
          const SizedBox(height: 30),
          const Text(
            'Rapports',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Transformez les signaux du marché en décisions.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 22),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Rechercher un rapport…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          if (reports.isEmpty)
            const EmptyState(
              title: 'Aucun rapport',
              message: 'Aucun rapport ne correspond à cette recherche.',
            )
          else
            for (final report in reports)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReportCard(report: report),
              ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF071B3B), Color(0xFF0B4C78)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'DOSSIER SPÉCIAL',
                  style: TextStyle(
                    color: Color(0xFF6ED8FF),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'L’IA redessine la veille concurrentielle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Lecture estimée • 8 min',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final WatchReport report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    report.date,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (report.isNew)
              const Chip(
                label: Text('NOUVEAU'),
                side: BorderSide.none,
                backgroundColor: Color(0xFFDDF8E8),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(report.summary),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Consulter'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF'),
            ),
          ],
        ),
      ],
    ),
  );
}
