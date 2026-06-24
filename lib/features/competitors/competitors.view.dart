import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import 'competitors.service.dart';

class CompetitorsView extends StatefulWidget {
  const CompetitorsView({super.key});

  @override
  State<CompetitorsView> createState() => _CompetitorsViewState();
}

class _CompetitorsViewState extends State<CompetitorsView> {
  final service = CompetitorsService();
  String query = '';

  @override
  Widget build(BuildContext context) {
    final results = service.search(query);
    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppTopBar(),
          const SizedBox(height: 30),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Concurrents',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Suivez les signaux qui comptent vraiment.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Rechercher un concurrent…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          if (results.isEmpty)
            const EmptyState(
              title: 'Aucun concurrent trouvé',
              message: 'Modifiez votre recherche ou ajoutez une entreprise.',
            )
          else
            for (final competitor in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompetitorCard(competitor: competitor),
              ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final name = TextEditingController();
    final website = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter un concurrent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: website,
              decoration: const InputDecoration(labelText: 'Site web'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isNotEmpty &&
                  website.text.trim().isNotEmpty) {
                setState(
                  () => service.add(
                    name: name.text.trim(),
                    website: website.text.trim(),
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Surveiller'),
          ),
        ],
      ),
    );
    name.dispose();
    website.dispose();
  }
}

class _CompetitorCard extends StatelessWidget {
  final Competitor competitor;
  const _CompetitorCard({required this.competitor});

  @override
  Widget build(BuildContext context) => Panel(
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.business_rounded, color: AppColors.blue),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                competitor.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                competitor.website,
                style: const TextStyle(color: AppColors.blue, fontSize: 12),
              ),
              Text(
                competitor.sector,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${competitor.score}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.blue,
              ),
            ),
            const Text(
              'SCORE',
              style: TextStyle(fontSize: 9, color: AppColors.muted),
            ),
            Text(
              '${competitor.growth >= 0 ? '+' : ''}${competitor.growth.toStringAsFixed(1)}%',
              style: TextStyle(
                color: competitor.growth >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
